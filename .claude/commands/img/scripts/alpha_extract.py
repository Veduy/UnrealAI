"""Extract alpha from white/black background pair using adaptive pixel distance."""
import sys
import numpy as np
from PIL import Image

if len(sys.argv) < 4:
    print("Usage: python alpha_extract.py <white.png> <black.png> <output.png>")
    sys.exit(1)

white_path, black_path, output_path = sys.argv[1], sys.argv[2], sys.argv[3]

W = np.asarray(Image.open(white_path).convert("RGB"), dtype=np.float64)
B = np.asarray(Image.open(black_path).convert("RGB"), dtype=np.float64)

# --- Adaptive background sampling ---
# Gemini doesn't produce perfect white/black, so sample actual bg colors from corners
h, w = W.shape[:2]
m = max(h, w) // 20  # 5% margin
corners = [(slice(0, m), slice(0, m)), (slice(0, m), slice(w - m, w)),
           (slice(h - m, h), slice(0, m)), (slice(h - m, h), slice(w - m, w))]
w_bg = np.mean([W[r, c].mean(axis=(0, 1)) for r, c in corners], axis=0)
b_bg = np.mean([B[r, c].mean(axis=(0, 1)) for r, c in corners], axis=0)
bg_dist = np.sqrt(np.sum((w_bg - b_bg) ** 2))

print(f"Background detected: white={w_bg.astype(int)}, black={b_bg.astype(int)}, dist={bg_dist:.1f}")

# --- Alpha from pixel distance (normalized by actual bg distance) ---
diff = W - B
pixel_dist = np.sqrt(np.sum(diff * diff, axis=2))
alpha = 1.0 - pixel_dist / bg_dist
alpha = np.clip(alpha, 0.0, 1.0)

# --- Threshold cleanup ---
# Background pixels: alpha < LOW -> fully transparent
# Subject pixels:    alpha > HIGH -> fully opaque
# Edge pixels:       remap LOW..HIGH -> 0..1 for smooth anti-aliasing
LOW, HIGH = 0.05, 0.92
alpha = np.where(alpha < LOW, 0.0, alpha)
alpha = np.where(alpha > HIGH, 1.0, alpha)
mid = (alpha > 0.0) & (alpha < 1.0)
if mid.any():
    alpha[mid] = (alpha[mid] - LOW) / (HIGH - LOW)
    alpha = np.clip(alpha, 0.0, 1.0)

# --- Un-premultiply color from black background ---
safe_alpha = np.where(alpha > 0, alpha, 1.0)
color = B / safe_alpha[..., np.newaxis]
color = np.where(alpha[..., np.newaxis] > 0, color, 0.0)
color = np.clip(color, 0.0, 255.0)

# --- Stats ---
total = alpha.size
n_trans = (alpha == 0).sum()
n_opaque = (alpha == 1).sum()
n_semi = total - n_trans - n_opaque
print(f"Alpha: transparent={n_trans/total*100:.1f}%, opaque={n_opaque/total*100:.1f}%, edge={n_semi/total*100:.1f}%")

# --- Save RGBA PNG ---
rgba = np.dstack((color, alpha * 255.0)).astype(np.uint8)
Image.fromarray(rgba, "RGBA").save(output_path)
print(f"Saved: {output_path}")
