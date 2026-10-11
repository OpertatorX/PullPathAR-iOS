from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "PullPathAR" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon-1024.png"
OUT.parent.mkdir(parents=True, exist_ok=True)

S = 2048
img = Image.new("RGB", (S, S), (10, 18, 32))
pix = img.load()

for y in range(S):
    for x in range(S):
        nx = (x - S * 0.18) / S
        ny = (y - S * 0.10) / S
        glow = max(0.0, 1.0 - math.sqrt(nx * nx + ny * ny) * 1.35)
        edge = (x + y) / (2 * S)
        r = int(9 + 10 * glow + 3 * edge)
        g = int(17 + 18 * glow + 5 * edge)
        b = int(31 + 30 * glow + 8 * edge)
        pix[x, y] = (min(r, 255), min(g, 255), min(b, 255))

route = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(route)
points = [(430, 1510), (720, 1190), (1040, 1260), (1350, 850), (1610, 540)]

for width, alpha in [(150, 24), (90, 35), (46, 255)]:
    d.line(points, fill=(61, 214, 193, alpha), width=width, joint="curve")

glow_layer = route.filter(ImageFilter.GaussianBlur(26))
img = Image.alpha_composite(img.convert("RGBA"), glow_layer)
img = Image.alpha_composite(img, route)

anchors = Image.new("RGBA", (S, S), (0, 0, 0, 0))
a = ImageDraw.Draw(anchors)
for i, (x, y) in enumerate(points):
    if i in (0, len(points) - 1):
        outer = 92
        inner = 45
    else:
        outer = 70
        inner = 30
    a.ellipse((x - outer, y - outer, x + outer, y + outer), fill=(10, 18, 32, 255), outline=(61, 214, 193, 255), width=18)
    a.ellipse((x - inner, y - inner, x + inner, y + inner), fill=(232, 246, 242, 255))

for angle in (-18, -6, 6, 18):
    cx, cy = 1500, 1480
    length = 180
    rad = math.radians(angle)
    x1 = cx + math.cos(rad) * 40
    y1 = cy + math.sin(rad) * 40
    x2 = cx + math.cos(rad) * length
    y2 = cy + math.sin(rad) * length
    a.line((x1, y1, x2, y2), fill=(207, 222, 228, 120), width=14)

img = Image.alpha_composite(img, anchors)
img = img.convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS)
img.save(OUT, "PNG", optimize=True)
print(OUT)
