from PIL import Image, ImageDraw
import os, math

SIZES = {
    'android/app/src/main/res/mipmap-mdpi': 48,
    'android/app/src/main/res/mipmap-hdpi': 72,
    'android/app/src/main/res/mipmap-xhdpi': 96,
    'android/app/src/main/res/mipmap-xxhdpi': 144,
    'android/app/src/main/res/mipmap-xxxhdpi': 192,
}

BASE = r'D:\jabiru Labs Tasks\Pet\pet-app'
GREEN = (46, 125, 50, 255)

def draw_paw(draw, cx, cy, s):
    # Create anti-aliased look by supersampling concept - use chunky shapes
    # Toes - big and chunky
    tw, th = s * 0.155, s * 0.24
    spread = s * 0.18
    toe_y = cy - s * 0.17
    for ang in (-28, -10, 10, 28):
        r = math.radians(ang)
        tx = cx + spread * math.sin(r)
        ty = toe_y + abs(ang) * s * 0.005
        draw.ellipse([tx - tw, ty - th, tx + tw, ty + th], fill='white')

    # Main pad - huge
    pw, ph = s * 0.35, s * 0.26
    py = cy + s * 0.06
    draw.ellipse([cx - pw, py - ph * 0.55, cx + pw, py + ph], fill='white')
    draw.ellipse([cx - pw * 0.5, py - ph * 0.8, cx + pw * 0.5, py + ph * 0.1], fill='white')

    # Lobes
    lr = s * 0.13
    ly = py + ph * 0.4
    draw.ellipse([cx - pw * 0.6 - lr, ly - lr * 0.5, cx - pw * 0.6 + lr, ly + lr * 1.5], fill='white')
    draw.ellipse([cx + pw * 0.6 - lr, ly - lr * 0.5, cx + pw * 0.6 + lr, ly + lr * 1.5], fill='white')
    draw.ellipse([cx - lr * 0.9, ly - lr * 0.3, cx + lr * 0.9, ly + lr * 1.8], fill='white')

def create_icon(size):
    img = Image.new('RGBA', (size, size), GREEN)
    draw = ImageDraw.Draw(img)
    sz = float(size)
    draw_paw(draw, sz / 2, sz / 2 + sz * 0.01, sz * 0.85)
    return img

for rel_path, size in SIZES.items():
    p = os.path.join(BASE, rel_path)
    os.makedirs(p, exist_ok=True)
    create_icon(size).save(os.path.join(p, 'ic_launcher.png'))

create_icon(1024).save(os.path.join(BASE, 'assets', 'icons', 'app_icon.png'))
create_icon(64).save(os.path.join(BASE, 'web', 'favicon.png'))
for n, s in [('Icon-192.png',192),('Icon-512.png',512),('Icon-maskable-192.png',192),('Icon-maskable-512.png',512)]:
    create_icon(s).save(os.path.join(BASE, 'web', 'icons', n))
print('Done.')
