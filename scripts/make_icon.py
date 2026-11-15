#!/usr/bin/env python3
"""Draws Yap Later's app icon: a cream speech bubble with a dollar sign, on the brand orange.
Usage: python3 scripts/make_icon.py   (needs Pillow; writes the 1024px PNG into the asset catalog)"""
from pathlib import Path
from PIL import Image, ImageDraw, ImageFont

S = 1024
BRAND, EDGE, CREAM, INK = (255, 90, 43), (199, 58, 18), (255, 244, 228), (27, 23, 34)
out = Path(__file__).resolve().parents[1] / "app/YapLater/Assets.xcassets/AppIcon.appiconset/AppIcon.png"

img = Image.new("RGB", (S * 2, S * 2), BRAND)  # draw at 2x, then downsample for smooth edges
d = ImageDraw.Draw(img)

def bubble(dx, dy, color):
    box = (300 + dx, 330 + dy, 1748 + dx, 1390 + dy)
    d.rounded_rectangle(box, radius=300, fill=color)
    d.polygon([(560 + dx, 1330 + dy), (880 + dx, 1330 + dy), (520 + dx, 1690 + dy)], fill=color)

bubble(0, 70, EDGE)   # the solid edge the bubble sits on
bubble(0, 0, CREAM)

font = None
for path, variation in [("/System/Library/Fonts/SFNSRounded.ttf", b"Black"),
                        ("/System/Library/Fonts/Supplemental/Arial Rounded Bold.ttf", None)]:
    try:
        font = ImageFont.truetype(path, 900)
        if variation:
            font.set_variation_by_name(variation)
        break
    except Exception:
        font = None
if font is None:
    font = ImageFont.load_default(900)
left, top, right, bottom = d.textbbox((0, 0), "$", font=font)
d.text((1024 - (left + right) / 2, 860 - (top + bottom) / 2), "$", font=font, fill=INK)

img.resize((S, S), Image.LANCZOS).save(out)
print("wrote", out)
