#!/usr/bin/env python3
"""Generate proper RGBA ZYNORA launcher icons and adaptive icon layers.

Outputs valid PNG files (8-bit RGBA, color type 6) for Android mipmaps and
adaptive icon foreground/background, plus a branded splash drawable.
"""
import io
import struct
import zlib
from pathlib import Path

try:
    from PIL import Image, ImageDraw, ImageFont
    HAVE_PIL = True
except Exception:
    HAVE_PIL = False

# Hardcoded absolute path to avoid any path-resolution race conditions.
REPO = Path('/home/user/zynora-repo')
RES = REPO / 'mobile' / 'android' / 'app' / 'src' / 'main' / 'res'

PRIMARY = (124, 77, 255)
ACCENT = (255, 181, 71)
BLUE = (33, 62, 140)
GOLD = (246, 195, 77)
WHITE = (255, 255, 255)


def gradient_fill(width, height, top=(124, 77, 255), bottom=(34, 22, 70)):
    raw = bytearray()
    for y in range(height):
        raw.append(0)
        ratio = y / max(1, height - 1)
        for x in range(width):
            r = int(top[0] * (1 - ratio) + bottom[0] * ratio)
            g = int(top[1] * (1 - ratio) + bottom[1] * ratio)
            b = int(top[2] * (1 - ratio) + bottom[2] * ratio)
            raw.extend(bytes([r, g, b, 255]))
    return bytes(raw)


def pack_png(rgba_bytes, width, height):
    def chunk(tag, data):
        return struct.pack('>I', len(data)) + tag + data + struct.pack('>I', zlib.crc32(tag + data) & 0xFFFFFFFF)
    sig = b'\x89PNG\r\n\x1a\n'
    ihdr = struct.pack('>IIBBBBB', width, height, 8, 6, 0, 0, 0)
    idat = zlib.compress(rgba_bytes, 9)
    return sig + chunk(b'IHDR', ihdr) + chunk(b'IDAT', idat) + chunk(b'IEND', b'')


def make_brand_canvas(size):
    if HAVE_PIL:
        img = Image.new('RGBA', (size, size), (0, 0, 0, 0))
        d = ImageDraw.Draw(img)
        radius = int(size * 0.22)
        for y in range(size):
            for x in range(size):
                inside = True
                cx = max(radius - x, x - (size - radius - 1), 0)
                cy = max(radius - y, y - (size - radius - 1), 0)
                if cx > 0 and cy > 0:
                    dx, dy = (cx, cy) if cx > cy else (cy, cx)
                    inside = dx * dx + dy * dy <= radius * radius
                if not inside:
                    img.putpixel((x, y), (0, 0, 0, 0))
        for y in range(size):
            ratio = y / max(1, size - 1)
            r = int(124 * (1 - ratio) + 21 * ratio)
            g = int(77 * (1 - ratio) + 32 * ratio)
            b = int(255 * (1 - ratio) + 86 * ratio)
            for x in range(size):
                p = img.getpixel((x, y))
                if p[3] > 0:
                    img.putpixel((x, y), (r, g, b, 255))
        for y in range(size):
            for x in range(size):
                dx = (x - size / 2) / (size / 2)
                dy = (y - size / 2) / (size / 2)
                dist = (dx * dx + dy * dy) ** 0.5
                if 0.88 <= dist <= 0.95:
                    img.putpixel((x, y), GOLD + (255,))
        try:
            font_paths = [
                '/usr/share/fonts/truetype/dejavu/DejaVuSans-Bold.ttf',
                '/usr/share/fonts/truetype/liberation/LiberationSans-Bold.ttf',
            ]
            font = None
            for fp in font_paths:
                try:
                    font = ImageFont.truetype(fp, int(size * 0.55))
                    break
                except Exception:
                    continue
            if font is not None:
                text = 'Z'
                bbox = d.textbbox((0, 0), text, font=font)
                tw, th = bbox[2] - bbox[0], bbox[3] - bbox[1]
                tx = (size - tw) // 2 - bbox[0]
                ty = (size - th) // 2 - bbox[1]
                d.text((tx + 4, ty + 5), text, fill=(220, 60, 60, 255), font=font)
                d.text((tx, ty), text, fill=GOLD + (255,), font=font)
        except Exception:
            pass
        buf = io.BytesIO()
        img.save(buf, format='PNG')
        return buf.getvalue()
    return pack_png(gradient_fill(size, size), size, size)


def write_icon(folder, name, size):
    target = RES / folder / name
    target.parent.mkdir(parents=True, exist_ok=True)
    target.write_bytes(make_brand_canvas(size))


PACKS = {
    'mipmap-mdpi': 48,
    'mipmap-hdpi': 72,
    'mipmap-xhdpi': 96,
    'mipmap-xxhdpi': 144,
    'mipmap-xxxhdpi': 192,
}

# Clean up any earlier misplaced dirs
import shutil
for bad in [REPO / 'mobile' / 'mobile', REPO / 'desktop', REPO / 'downscaled']:
    if bad.exists():
        shutil.rmtree(bad, ignore_errors=True)

for folder, size in PACKS.items():
    write_icon(folder, 'ic_launcher.png', size)
    write_icon(folder, 'ic_launcher_round.png', size)

adaptive_xml = """<?xml version="1.0" encoding="utf-8"?>
<adaptive-icon xmlns:android="http://schemas.android.com/apk/res/android">
    <background android:drawable="@drawable/ic_launcher_background" />
    <foreground android:drawable="@drawable/ic_launcher_foreground" />
    <monochrome android:drawable="@drawable/ic_launcher_foreground" />
</adaptive-icon>
"""
for folder in ('mipmap-anydpi-v26', 'mipmap-anydpi-v26'):
    (RES / folder).mkdir(parents=True, exist_ok=True)
    (RES / folder / 'ic_launcher.xml').write_text(adaptive_xml)
    (RES / folder / 'ic_launcher_round.xml').write_text(adaptive_xml)

# Adaptive-icon layers (Android 8.0+)
write_icon('drawable', 'ic_launcher_foreground.png', 432)
write_icon('drawable-v21', 'ic_launcher_foreground.png', 432)
write_icon('drawable', 'ic_launcher_background.png', 432)
write_icon('drawable-v21', 'ic_launcher_background.png', 432)

# Splash background drawable (gradient + branded backdrop)
splash_bg = RES / 'drawable' / 'launch_background.xml'
splash_bg.parent.mkdir(parents=True, exist_ok=True)
splash_bg.write_text("""<?xml version="1.0" encoding="utf-8"?>
<layer-list xmlns:android="http://schemas.android.com/apk/res/android">
    <item>
        <shape android:shape="rectangle">
            <gradient
                android:type="linear"
                android:angle="135"
                android:startColor="#7C4DFF"
                android:centerColor="#21D4FD"
                android:endColor="#FFB457" />
        </shape>
    </item>
</layer-list>
""")

print('Generated ZYNORA launcher icons into', RES)
print('Files written:')
import os
for root, _, files in os.walk(RES):
    for f in sorted(files):
        if f.endswith(('.png', '.xml')):
            print('  ', os.path.relpath(os.path.join(root, f), REPO / 'mobile'))
