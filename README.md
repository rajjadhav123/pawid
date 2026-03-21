# 🐾 PawID — AI Dog Breed Detection System

<div align="center">

![PawID Banner](https://img.shields.io/badge/PawID-Dog%20Breed%20Detection-c97c2a?style=for-the-badge&logo=tensorflow&logoColor=white)

[![Python](https://img.shields.io/badge/Python-3.11-3776AB?style=flat-square&logo=python&logoColor=white)](https://python.org)
[![TensorFlow](https://img.shields.io/badge/TensorFlow-2.13-FF6F00?style=flat-square&logo=tensorflow&logoColor=white)](https://tensorflow.org)
[![Flask](https://img.shields.io/badge/Flask-3.0-000000?style=flat-square&logo=flask&logoColor=white)](https://flask.palletsprojects.com)
[![MobileNetV2](https://img.shields.io/badge/Model-MobileNetV2-brightgreen?style=flat-square)](https://keras.io/api/applications/mobilenet/)
[![License](https://img.shields.io/badge/License-MIT-blue?style=flat-square)](LICENSE)

**Upload a dog photo → Get the breed, diet, health, temperament & India suitability in seconds.**

*Final Year ML Project · Transfer Learning · Built with ❤️ in India*

</div>

---

## 📸 Screenshots

| Landing Page | Breed Detection | Grad-CAM Heatmap |
|:---:|:---:|:---:|
| ![Landing](https://via.placeholder.com/280x160/4a2e12/e8a84b?text=Landing+Page) | ![Detection](https://via.placeholder.com/280x160/4a2e12/e8a84b?text=Breed+Result) | ![GradCAM](https://via.placeholder.com/280x160/4a2e12/e8a84b?text=Grad-CAM) |

| Compare Breeds | Analytics Dashboard | PDF Report |
|:---:|:---:|:---:|
| ![Compare](https://via.placeholder.com/280x160/4a2e12/e8a84b?text=Compare) | ![Analytics](https://via.placeholder.com/280x160/4a2e12/e8a84b?text=Analytics) | ![PDF](https://via.placeholder.com/280x160/4a2e12/e8a84b?text=PDF+Report) |

> 💡 **Tip:** Replace placeholder images above with real screenshots from your running app.

---

## ✨ Features

| Feature | Description |
|---|---|
| 🔍 **AI Breed Detection** | MobileNetV2 transfer learning identifies 120+ dog breeds from a single photo |
| 🔬 **Grad-CAM Explainability** | Heatmap overlay showing which regions the AI focused on to make its prediction |
| ⚖️ **Breed Comparison** | Side-by-side table comparing any two breeds across 15+ attributes |
| 📄 **PDF Report Export** | Downloadable 2-page breed report with complete information |
| 📊 **Analytics Dashboard** | Live detection statistics — top breeds, confidence distribution, daily activity |
| 📸 **Live Camera** | Webcam and mobile camera support — point and detect in real time |
| 🕐 **Detection History** | localStorage-based history of all past detections with thumbnails |
| 🇮🇳 **India Focus** | India Suitability Score for every breed + 10 rare Indian breeds in database |
| 🤖 **PawBot AI Chat** | Integrated chatbot (via Groq API) for breed-specific questions |
| ⚠️ **Confidence Warning** | Automatic warning when model confidence is below 45% |

---

## 🏗️ Architecture

```
┌─────────────────────────────────────────────────────────┐
│                    PawID System                          │
├─────────────┬──────────────────┬────────────────────────┤
│  Frontend   │    Flask API     │      ML Pipeline       │
│             │                  │                        │
│ HTML/CSS/JS │  /api/detect     │  Image Preprocessing   │
│ Three.js 3D │  /api/gradcam    │  ↓                     │
│ Chart.js    │  /api/compare    │  MobileNetV2 (224×224) │
│ jsPDF       │  /api/analytics  │  ↓                     │
│ PawBot Chat │  /api/breeds     │  Softmax Top-5         │
│             │  /api/health     │  ↓                     │
│             │                  │  Grad-CAM Heatmap      │
└─────────────┴──────────────────┴────────────────────────┘
```

---

## 🧠 Model Details

| Property | Value |
|---|---|
| **Base Model** | MobileNetV2 (ImageNet pretrained) |
| **Transfer Learning** | Fine-tuned on Stanford Dogs dataset |
| **Input Size** | 224 × 224 × 3 |
| **Output Classes** | 120 breeds |
| **Training Images** | 20,000+ |
| **Top-K Predictions** | Top-5 with softmax probabilities |
| **Explainability** | Grad-CAM via Conv_1 layer activation maps |
| **Framework** | TensorFlow / Keras |

---

## 📁 Project Structure

```
pawid/
├── app.py                  # Flask backend — all API routes
├── breed_database.py       # 149-breed database with full info
├── requirements.txt        # Python dependencies
├── render.yaml             # Render.com deployment config
├── analytics_data.json     # Auto-generated detection analytics
│
├── models/
│   ├── pawid_final.keras   # Trained MobileNetV2 model
│   └── class_indices.json  # Class index → breed name mapping
│
├── templates/
│   ├── landing.html        # Landing page (served at /)
│   └── index.html          # Main app (served at /app)
│
└── static/
    └── uploads/            # Temporary image uploads
```

---

## 🚀 Quick Start

### Prerequisites
- Python 3.11
- pip

### Installation

```bash
# 1. Clone the repository
git clone https://github.com/rajjadhav123/pawid.git
cd pawid

# 2. Install dependencies
pip install -r requirements.txt

# 3. Set up environment variables
cp .env.example .env
# Edit .env and add your GROQ_API_KEY

# 4. Run the app
py app.py
```

### Open in browser
```
http://localhost:5000          ← Landing page
http://localhost:5000/app      ← Detection app
```

---

## 🔌 API Reference

### `POST /api/detect`
Detect breed from uploaded image.

**Request:** `multipart/form-data` with `image` field

**Response:**
```json
{
  "success": true,
  "demo_mode": false,
  "predictions": [
    {"rank": 1, "breed": "Golden Retriever", "confidence": 0.942, "percentage": "94.2%"}
  ],
  "top_breed": {"name": "Golden Retriever", "confidence": 0.942},
  "breed_info": { ... },
  "gradcam": "base64_encoded_png",
  "low_confidence": false
}
```

---

### `GET /api/compare?breed1=X&breed2=Y`
Compare two breeds side by side.

```json
{
  "success": true,
  "breed1": { ... },
  "breed2": { ... }
}
```

---

### `GET /api/analytics`
Get detection statistics.

```json
{
  "success": true,
  "total_detections": 28,
  "top_breeds": [{"breed": "Golden Retriever", "count": 5}],
  "daily_counts": [...],
  "confidence_buckets": {"0-40": 2, "40-60": 3, "60-80": 8, "80-100": 15}
}
```

---

### `GET /api/breeds`
List all breeds in database. Optional `?q=search_term`.

### `GET /api/health`
Server and model health check.

### `POST /api/chat`
PawBot AI assistant (requires GROQ_API_KEY).

---

## 🇮🇳 India-Specific Features

PawID is built with Indian dog owners in mind:

- **India Suitability Score** (0–100) for every breed — considers climate, apartment living, food availability
- **Indian Climate Notes** — heat/cold tolerance mapped to Indian weather zones
- **10 Native Indian Breeds** — Mudhol Hound, Rajapalayam, Indian Pariah Dog, Chippiparai, Kombai, and more
- **PawBot tuned for India** — advice specific to Indian cities, food, lifestyle

---

## ⚙️ Environment Variables

Create a `.env` file in the project root:

```env
GROQ_API_KEY=your_groq_api_key_here
MODEL_PATH=models/pawid_final.keras
CLASS_INDICES_PATH=models/class_indices.json
```

Get a free Groq API key at [console.groq.com](https://console.groq.com)

---

## 📦 Dependencies

```
flask          — Web framework
tensorflow     — ML inference + Grad-CAM
numpy          — Array operations
pillow         — Image processing
python-dotenv  — Environment variables
requests       — HTTP client (Groq API)
gunicorn       — Production WSGI server
```

---

## 🧪 Testing the API

```bash
# Health check
curl http://localhost:5000/api/health

# List all breeds
curl http://localhost:5000/api/breeds

# Get breed info
curl http://localhost:5000/api/breed/Golden+Retriever

# Compare two breeds
curl "http://localhost:5000/api/compare?breed1=Golden+Retriever&breed2=Labrador+Retriever"

# Analytics
curl http://localhost:5000/api/analytics
```

---

## 🤝 Contributing

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

---

## 📄 License

Distributed under the MIT License. See `LICENSE` for more information.

---

## 👤 Author

**Raj Jadhav**
- GitHub: [@rajjadhav123](https://github.com/rajjadhav123)

---

## 🙏 Acknowledgements

- [Stanford Dogs Dataset](http://vision.stanford.edu/aditya86/ImageNetDogs/) — Training data
- [TensorFlow / Keras](https://tensorflow.org) — ML framework
- [MobileNetV2](https://arxiv.org/abs/1801.04381) — Base model architecture
- [Groq](https://groq.com) — LLM API for PawBot
- [jsPDF](https://github.com/parallax/jsPDF) — PDF generation

---

<div align="center">
  <b>⭐ Star this repo if you found it useful!</b><br><br>
  Built with ❤️ for the love of dogs and deep learning
</div>
