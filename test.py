import tensorflow as tf
import numpy as np
from PIL import Image

# Load model
model = tf.keras.models.load_model('models/pawid_final.keras')

# Create a random test image (300x300x3)
test_img = np.random.rand(1, 300, 300, 3).astype(np.float32)

# Run prediction
preds = model.predict(test_img, verbose=0)

print(f"Output shape: {preds.shape}")
print(f"Sum of probabilities: {preds.sum():.4f}")  # Should be 1.0
print(f"Max confidence: {preds.max():.4f}")  # Should be reasonable
print(f"Top 5 predictions: {preds[0].argsort()[-5:][::-1]}")