from dotenv import load_dotenv
load_dotenv()
import os
import json
import numpy as np
from pathlib import Path
from flask import Flask, request, jsonify, render_template
from werkzeug.utils import secure_filename
from PIL import Image
import io
import urllib.request as urlreq
import urllib.error
 
from breed_database import BREED_DATABASE, get_breed_info, get_all_breed_names
import base64
import datetime

# ── Analytics store ──
ANALYTICS_FILE = 'analytics_data.json'

def load_analytics():
    try:
        if os.path.exists(ANALYTICS_FILE):
            with open(ANALYTICS_FILE) as f:
                return json.load(f)
    except Exception:
        pass
    return {
        'total_detections': 0,
        'breed_counts': {},
        'daily_counts': {},
        'confidence_buckets': {'0-40': 0, '40-60': 0, '60-80': 0, '80-100': 0}
    }

def save_analytics(data):
    try:
        with open(ANALYTICS_FILE, 'w') as f:
            json.dump(data, f)
    except Exception:
        pass

def record_detection(breed_name, confidence, is_demo):
    """Record a detection — skips demo mode"""
    if is_demo:
        return
    data = load_analytics()
    data['total_detections'] += 1
    data['breed_counts'][breed_name] = data['breed_counts'].get(breed_name, 0) + 1
    today = datetime.date.today().isoformat()
    data['daily_counts'][today] = data['daily_counts'].get(today, 0) + 1
    pct = confidence * 100
    if pct < 40:
        data['confidence_buckets']['0-40'] += 1
    elif pct < 60:
        data['confidence_buckets']['40-60'] += 1
    elif pct < 80:
        data['confidence_buckets']['60-80'] += 1
    else:
        data['confidence_buckets']['80-100'] += 1
    save_analytics(data)

app = Flask(__name__)
app.config['MAX_CONTENT_LENGTH'] = 16 * 1024 * 1024
app.config['UPLOAD_FOLDER'] = 'static/uploads'
ALLOWED_EXTENSIONS = {'png', 'jpg', 'jpeg', 'webp', 'gif'}
 
IMG_SIZE = 224  # ← FIXED! Must match training (MobileNetV2 = 224)
MODEL_PATH = os.environ.get('MODEL_PATH', 'models/pawid_final.keras')
CLASS_INDICES_PATH = os.environ.get('CLASS_INDICES_PATH', 'models/class_indices.json')
 
os.makedirs(app.config['UPLOAD_FOLDER'], exist_ok=True)
 
_model = None
_class_indices = None
_model_working = False
 
def load_model():
    """Load model with diagnostics"""
    global _model, _class_indices, _model_working
 
    if _model is not None:
        return _model, _class_indices, _model_working
 
    # Load class indices
    if os.path.exists(CLASS_INDICES_PATH):
        with open(CLASS_INDICES_PATH) as f:
            _class_indices = json.load(f)
        print(f"✅ Class indices loaded: {len(_class_indices)} classes")
    else:
        print(f"⚠️  Class indices not found")
        _class_indices = {str(i): name for i, name in enumerate(get_all_breed_names())}
 
    # Try to load model
    if os.path.exists(MODEL_PATH):
        try:
            import tensorflow as tf
            _model = tf.keras.models.load_model(MODEL_PATH)
            
            # TEST if model works
            test_img = np.random.rand(1, IMG_SIZE, IMG_SIZE, 3).astype(np.float32)
            test_pred = _model.predict(test_img, verbose=0)
            
            if test_pred.max() < 0.005:
                print("❌ Model loaded but outputs are broken (max confidence < 0.5%)")
                _model_working = False
            else:
                print(f"✅ Model loaded and working! Test max confidence: {test_pred.max():.2%}")
                _model_working = True
                
        except Exception as e:
            print(f"❌ Could not load model: {e}")
            _model = None
            _model_working = False
    else:
        print(f"⚠️  Model file not found at {MODEL_PATH}")
        _model = None
        _model_working = False
 
    if not _model_working:
        print("\n" + "="*60)
        print("⚠️  RUNNING IN DEMO MODE")
        print("="*60)
        print("Your custom model is not working. Possible fixes:")
        print("1. Re-download pawid_model.zip from Google Colab")
        print("2. Make sure you ran ALL cells in the training notebook")
        print("3. Check that the .keras file is not corrupted (should be 13+ MB)")
        print("4. Verify IMG_SIZE in app.py matches training (224 for MobileNetV2)")
        print("="*60 + "\n")
 
    return _model, _class_indices, _model_working
 
 
def allowed_file(filename):
    return '.' in filename and filename.rsplit('.', 1)[1].lower() in ALLOWED_EXTENSIONS
 
 
def preprocess_image(image_bytes):
    """Preprocess image to 224x224"""
    img = Image.open(io.BytesIO(image_bytes)).convert('RGB')
    img = img.resize((IMG_SIZE, IMG_SIZE), Image.LANCZOS)
    arr = np.array(img, dtype=np.float32) / 255.0
    arr = np.expand_dims(arr, axis=0)
    return arr


def generate_gradcam(image_bytes, pred_class_idx):
    """
    Grad-CAM for nested MobileNetV2.
    Uses persistent GradientTape watching input tensor.
    Both conv extractor and full model run inside the same tape.
    """
    model, class_indices, model_working = load_model()
    if not model_working or model is None:
        return None

    try:
        import tensorflow as tf

        # Build conv extractor: mobilenet input → Conv_1 output
        mobilenet  = model.get_layer('mobilenetv2_1.00_224')
        conv_layer = mobilenet.get_layer('Conv_1')
        conv_model = tf.keras.models.Model(
            inputs  = mobilenet.input,
            outputs = conv_layer.output,
            name    = 'gradcam_extractor'
        )

        img_array  = preprocess_image(image_bytes)
        img_tensor = tf.constant(img_array, dtype=tf.float32)

        # Persistent tape — watch input, run both models inside
        with tf.GradientTape(persistent=True) as tape:
            tape.watch(img_tensor)
            conv_outputs = conv_model(img_tensor, training=False)
            predictions  = model(img_tensor, training=False)
            loss         = predictions[:, pred_class_idx]

        grads = tape.gradient(loss, conv_outputs)
        del tape

        if grads is None:
            # Fallback: mean absolute activation map
            conv_np = conv_outputs.numpy()[0]
            heatmap = np.mean(np.abs(conv_np), axis=-1)
        else:
            pooled_grads = tf.reduce_mean(grads, axis=(0, 1, 2)).numpy()
            conv_np      = conv_outputs.numpy()[0]
            heatmap      = np.einsum('hwc,c->hw', conv_np, pooled_grads)

        # ReLU + normalize
        heatmap = np.maximum(heatmap, 0)
        if heatmap.max() > 1e-8:
            heatmap = heatmap / heatmap.max()

        # Resize to 224×224
        heatmap_resized = np.array(
            Image.fromarray(np.uint8(heatmap * 255))
                 .resize((IMG_SIZE, IMG_SIZE), Image.LANCZOS)
        )

        # Jet colormap
        g  = heatmap_resized.astype(np.float32) / 255.0
        r  = np.clip(1.5 - np.abs(g * 4 - 3), 0, 1)
        gn = np.clip(1.5 - np.abs(g * 4 - 2), 0, 1)
        b  = np.clip(1.5 - np.abs(g * 4 - 1), 0, 1)
        heatmap_colored = (np.stack([r, gn, b], axis=-1) * 255).astype(np.uint8)

        # Blend over original
        original = np.array(
            Image.open(io.BytesIO(image_bytes))
                 .convert('RGB')
                 .resize((IMG_SIZE, IMG_SIZE), Image.LANCZOS)
        )
        overlay = (original * 0.5 + heatmap_colored * 0.5).clip(0, 255).astype(np.uint8)

        # Base64 PNG
        buf = io.BytesIO()
        Image.fromarray(overlay).save(buf, format='PNG')
        buf.seek(0)
        result = base64.b64encode(buf.read()).decode('utf-8')
        print(f"✅ Grad-CAM success — size={len(result)} chars")
        return result

    except Exception as e:
        print(f"❌ Grad-CAM error: {type(e).__name__}: {e}")
        import traceback; traceback.print_exc()
        return None
 
 
def predict_breed_from_image(image_bytes, top_k=5):
    """Run prediction with fallback"""
    model, class_indices, model_working = load_model()
 
    if not model_working or model is None:
        # DEMO MODE
        import random
        import hashlib
        
        img_hash = int(hashlib.md5(image_bytes).hexdigest(), 16)
        random.seed(img_hash)
        
        breeds = list(BREED_DATABASE.keys())
        top_breed_idx = img_hash % len(breeds)
        top_breed = breeds[top_breed_idx]
        
        results = []
        remaining = 1.0
        
        top_conf = 0.40 + (img_hash % 30) / 100.0
        results.append({
            'rank': 1,
            'breed': top_breed,
            'confidence': round(top_conf, 4),
            'percentage': f'{top_conf * 100:.1f}%'
        })
        remaining -= top_conf
        
        other_breeds = [b for b in breeds if b != top_breed]
        random.shuffle(other_breeds)
        
        for i, breed in enumerate(other_breeds[:top_k-1], 2):
            conf = remaining * random.uniform(0.3, 0.6) if i < top_k else remaining
            remaining -= conf
            if remaining < 0:
                remaining = 0.01
            results.append({
                'rank': i,
                'breed': breed,
                'confidence': round(conf, 4),
                'percentage': f'{conf * 100:.1f}%'
            })
        
        return results, True
 
    # REAL MODEL
    try:
        arr = preprocess_image(image_bytes)
        preds = model.predict(arr, verbose=0)[0]
        
        if preds.max() < 0.005:
            print(f"⚠️  Model prediction confidence too low: {preds.max():.4f}")
            return predict_breed_from_image(image_bytes, top_k)
        
        top_indices = preds.argsort()[-top_k:][::-1]
 
        results = []
        for rank, idx in enumerate(top_indices, 1):
            breed_name = class_indices.get(str(idx), f'Unknown_{idx}')
            conf = float(preds[idx])
            results.append({
                'rank': rank,
                'breed': breed_name,
                'confidence': round(conf, 4),
                'percentage': f'{conf * 100:.1f}%'
            })
 
        return results, False
        
    except Exception as e:
        print(f"❌ Prediction error: {e}")
        return predict_breed_from_image(image_bytes, top_k)
 
 
@app.route('/')
def landing():
    return render_template('landing.html')

@app.route('/app')
def index():
    return render_template('index.html')
 
 
@app.route('/api/detect', methods=['POST'])
def detect_breed():
    if 'image' not in request.files:
        return jsonify({'error': 'No image file provided'}), 400

    file = request.files['image']
    if file.filename == '':
        return jsonify({'error': 'No file selected'}), 400

    if not allowed_file(file.filename):
        return jsonify({'error': f'File type not allowed'}), 400

    image_bytes = file.read()

    try:
        predictions, is_demo = predict_breed_from_image(image_bytes)
    except Exception as e:
        return jsonify({'error': f'Prediction failed: {str(e)}'}), 500

    top_breed = predictions[0]['breed']
    top_conf  = predictions[0]['confidence']
    breed_info = get_breed_info(top_breed)

    # ── Record real detection in analytics ──
    record_detection(top_breed, top_conf, is_demo)

    # ── Grad-CAM (only for real model, not demo) ──
    gradcam_image = None
    if not is_demo:
        model, class_indices, _ = load_model()
        # Find predicted class index
        pred_idx = 0
        if class_indices:
            for k, v in class_indices.items():
                if v == top_breed:
                    pred_idx = int(k)
                    break
        gradcam_image = generate_gradcam(image_bytes, pred_idx)

    # ── Confidence warning flag ──
    low_confidence = top_conf < 0.45

    response = {
        'success': True,
        'demo_mode': is_demo,
        'predictions': predictions,
        'top_breed': {
            'name': top_breed,
            'confidence': top_conf,
            'percentage': predictions[0]['percentage'],
        },
        'breed_info': breed_info,
        'alternatives': predictions[1:],
        'gradcam': gradcam_image,      # base64 PNG or null
        'low_confidence': low_confidence,
    }

    return jsonify(response)
 
 
@app.route('/api/breed/<breed_name>', methods=['GET'])
def get_breed(breed_name):
    breed_name = breed_name.replace('-', ' ').replace('_', ' ')
    info = get_breed_info(breed_name)
    if info is None:
        return jsonify({'error': f'Breed "{breed_name}" not found'}), 404
    return jsonify({'success': True, 'breed_info': info})
 
 
@app.route('/api/breeds', methods=['GET'])
def list_breeds():
    query = request.args.get('q', '').strip()
    if query:
        from breed_database import search_breeds
        breeds = search_breeds(query)
    else:
        breeds = get_all_breed_names()
    return jsonify({'success': True, 'count': len(breeds), 'breeds': breeds})
 
 
@app.route('/api/health', methods=['GET'])
def health_check():
    model, class_indices, model_working = load_model()
    return jsonify({
        'status': 'running',
        'model_loaded': model is not None,
        'model_working': model_working,
        'total_breeds_in_db': len(BREED_DATABASE),
        'total_model_classes': len(class_indices) if class_indices else 0,
        'demo_mode': not model_working,
        'img_size': IMG_SIZE
    })
 
 
@app.route('/api/chat', methods=['POST'])
def chat_proxy():
    """Proxy Groq API — free, fast, uses requests library"""
    GROQ_API_KEY = os.environ.get('GROQ_API_KEY', '')
    if not GROQ_API_KEY:
        return jsonify({'content': [{'type': 'text', 'text': 'GROQ_API_KEY not set in .env file.'}]}), 200

    try:
        body = request.get_json(force=True, silent=True)
        if not body:
            return jsonify({'content': [{'type': 'text', 'text': 'Bad request.'}]}), 200

        messages    = body.get('messages', [])
        system_text = body.get('system', '')

        while messages and messages[0].get('role') != 'user':
            messages.pop(0)
        if not messages:
            return jsonify({'content': [{'type': 'text', 'text': 'No question received!'}]}), 200

        messages = messages[-6:]

        breed_line = ''
        if 'detected:' in system_text:
            try:
                breed_line = system_text.split('detected: "')[1].split('"')[0]
            except Exception:
                breed_line = ''

        short_system = (
            "You are PawBot, a friendly dog breed expert inside a dog breed detection app. "
            "Give concise helpful answers in 2-3 sentences. "
            "Specialise in advice for Indian climate, city apartments, and Indian lifestyle. "
            "Be warm, use 1-2 emojis."
        )
        if breed_line:
            short_system += " Currently discussing: " + breed_line + "."

        groq_messages = [{'role': 'system', 'content': short_system}]
        for msg in messages:
            groq_messages.append({
                'role':    msg.get('role', 'user'),
                'content': str(msg.get('content', '')).strip()
            })

        print("Groq chat | key=gsk_***" + GROQ_API_KEY[-4:] + " | msgs=" + str(len(groq_messages)))

        try:
            import requests as req_lib
            resp = req_lib.post(
                'https://api.groq.com/openai/v1/chat/completions',
                json={
                    'model':       'llama-3.1-8b-instant',
                    'messages':    groq_messages,
                    'max_tokens':  300,
                    'temperature': 0.7,
                },
                headers={
                    'Authorization': 'Bearer ' + GROQ_API_KEY,
                    'Content-Type':  'application/json',
                },
                timeout=30
            )
            result = resp.json()
            print("Groq status: " + str(resp.status_code))
            print("Groq raw: " + str(result)[:200])

        except ImportError:
            # fallback to urllib if requests not installed
            payload = json.dumps({
                'model':       'llama-3.1-8b-instant',
                'messages':    groq_messages,
                'max_tokens':  300,
                'temperature': 0.7,
                'stream':      False,
            }).encode('utf-8')

            hreq = urlreq.Request(
                'https://api.groq.com/openai/v1/chat/completions',
                data    = payload,
                headers = {
                    'Content-Type':    'application/json',
                    'Authorization':   'Bearer ' + GROQ_API_KEY,
                    'User-Agent':      'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
                    'Accept':          'application/json',
                    'Accept-Language': 'en-US,en;q=0.9',
                },
                method = 'POST'
            )
            with urlreq.urlopen(hreq, timeout=30) as r:
                result = json.loads(r.read().decode('utf-8'))

        reply_text = ''
        if 'choices' in result and result['choices']:
            reply_text = result['choices'][0].get('message', {}).get('content', '').strip()
        elif 'error' in result:
            err = result['error']
            msg_text = err.get('message', str(err)) if isinstance(err, dict) else str(err)
            print("Groq error: " + msg_text)
            reply_text = 'API error: ' + msg_text

        if not reply_text:
            reply_text = 'Empty response. Please try again!'

        print("Reply: " + reply_text[:120])
        return jsonify({'content': [{'type': 'text', 'text': reply_text}]})

    except Exception as e:
        print("Chat exception: " + type(e).__name__ + ": " + str(e))
        return jsonify({'content': [{'type': 'text', 'text': 'Error: ' + str(e)}]})


@app.route('/api/analytics', methods=['GET'])
def get_analytics():
    """Return analytics data for the dashboard"""
    data = load_analytics()
    # Top 10 breeds
    top_breeds = sorted(data['breed_counts'].items(), key=lambda x: x[1], reverse=True)[:10]
    # Last 14 days
    today = datetime.date.today()
    last_14 = []
    for i in range(13, -1, -1):
        d = (today - datetime.timedelta(days=i)).isoformat()
        last_14.append({'date': d, 'count': data['daily_counts'].get(d, 0)})
    return jsonify({
        'success': True,
        'total_detections': data['total_detections'],
        'top_breeds': [{'breed': b, 'count': c} for b, c in top_breeds],
        'daily_counts': last_14,
        'confidence_buckets': data['confidence_buckets'],
        'total_breeds_in_db': len(BREED_DATABASE),
    })


@app.route('/api/compare', methods=['GET'])
def compare_breeds():
    """Compare two breeds side by side"""
    b1 = request.args.get('breed1', '').replace('-', ' ').replace('_', ' ')
    b2 = request.args.get('breed2', '').replace('-', ' ').replace('_', ' ')
    if not b1 or not b2:
        return jsonify({'error': 'Provide breed1 and breed2 query params'}), 400
    info1 = get_breed_info(b1)
    info2 = get_breed_info(b2)
    if not info1:
        return jsonify({'error': f'Breed "{b1}" not found'}), 404
    if not info2:
        return jsonify({'error': f'Breed "{b2}" not found'}), 404
    return jsonify({'success': True, 'breed1': info1, 'breed2': info2})


if __name__ == '__main__':
    print("\n" + "="*60)
    print("🐾 PawID — Dog Breed Detection System")
    print("="*60)
    load_model()
    print(f"📊 Breed database: {len(BREED_DATABASE)} breeds")
    print(f"🖼️  Image size: {IMG_SIZE}x{IMG_SIZE}")
    print(f"🌐 Server starting at http://localhost:5000")
    print("="*60 + "\n")
    app.run(debug=True, host='0.0.0.0', port=5000)