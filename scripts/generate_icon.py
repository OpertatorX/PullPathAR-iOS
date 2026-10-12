from pathlib import Path
from PIL import Image, ImageDraw, ImageFilter
import math, random

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "PullPathAR" / "Resources" / "Assets.xcassets" / "AppIcon.appiconset" / "AppIcon-1024.png"
OUT.parent.mkdir(parents=True, exist_ok=True)

S = 3072
random.seed(7)

# Full-bleed graphite background (Apple applies the corner mask itself).
img = Image.new("RGB", (S, S), (8, 9, 12))
pix = img.load()
for y in range(S):
    fy = y / S
    for x in range(S):
        fx = x / S
        # Warm key light top-right + subtle cool lift top-left + vignette.
        warm_d = math.hypot(fx - 0.82, fy - 0.08)
        cool_d = math.hypot(fx - 0.12, fy - 0.10)
        warm = max(0.0, 1.0 - warm_d * 1.45)
        cool = max(0.0, 1.0 - cool_d * 1.70)
        edge = math.hypot(fx - 0.5, fy - 0.5) / 0.72
        vignette = max(0.0, min(1.0, edge))
        r = 9 + int(22 * warm + 5 * cool - 5 * vignette)
        g = 10 + int(14 * warm + 10 * cool - 5 * vignette)
        b = 14 + int(8 * warm + 18 * cool - 4 * vignette)
        # Almost invisible grain prevents a cheap flat-gradient look.
        grain = random.choice((0, 0, 0, 0, 1, -1))
        pix[x, y] = (max(0, min(255, r + grain)), max(0, min(255, g + grain)), max(0, min(255, b + grain)))

img = img.convert("RGBA")

# Helper for sampled cubic Bézier paths.
def bezier(p0, p1, p2, p3, n=90):
    pts = []
    for i in range(n + 1):
        t = i / n
        u = 1 - t
        x = u**3*p0[0] + 3*u*u*t*p1[0] + 3*u*t*t*p2[0] + t**3*p3[0]
        y = u**3*p0[1] + 3*u*u*t*p1[1] + 3*u*t*t*p2[1] + t**3*p3[1]
        pts.append((int(x), int(y)))
    return pts

def catmull_path():
    # A single P-like cable path: grounded tail, large loop, clean return.
    return (
        bezier((820, 2420), (850, 2050), (880, 1570), (1120, 1260), 80)[:-1]
        + bezier((1120, 1260), (1390, 930), (1940, 840), (2250, 1040), 80)[:-1]
        + bezier((2250, 1040), (2550, 1240), (2480, 1640), (2160, 1740), 80)[:-1]
        + bezier((2160, 1740), (1770, 1850), (1470, 1600), (1280, 1470), 70)
    )

path = catmull_path()

# Reel behind the cable path.
reel = Image.new("RGBA", (S, S), (0, 0, 0, 0))
rd = ImageDraw.Draw(reel)
cx, cy = 2140, 1395

# Soft amber halo behind the reel.
halo = Image.new("RGBA", (S, S), (0, 0, 0, 0))
hd = ImageDraw.Draw(halo)
hd.ellipse((cx-650, cy-650, cx+650, cy+650), fill=(255, 133, 35, 85))
halo = halo.filter(ImageFilter.GaussianBlur(135))
img = Image.alpha_composite(img, halo)

# Reel body: nested rings create metallic depth.
for radius, fill in [
    (610, (23, 20, 20, 255)),
    (570, (122, 72, 32, 255)),
    (540, (20, 20, 22, 255)),
    (490, (58, 43, 34, 255)),
    (455, (12, 13, 16, 255)),
]:
    rd.ellipse((cx-radius, cy-radius, cx+radius, cy+radius), fill=fill)

# Bronze outer rim + titanium highlight arcs.
rd.ellipse((cx-575, cy-575, cx+575, cy+575), outline=(226, 145, 72, 255), width=34)
rd.arc((cx-563, cy-563, cx+563, cy+563), 210, 335, fill=(255, 225, 184, 235), width=18)
rd.arc((cx-560, cy-560, cx+560, cy+560), 28, 135, fill=(118, 72, 39, 220), width=18)

# Cable coils inside the reel.
for rr in range(365, 185, -40):
    rd.ellipse((cx-rr, cy-rr, cx+rr, cy+rr), outline=(41, 44, 49, 255), width=26)
    rd.arc((cx-rr, cy-rr, cx+rr, cy+rr), 198, 338, fill=(105, 110, 116, 210), width=9)

# Reel hub.
rd.ellipse((cx-180, cy-180, cx+180, cy+180), fill=(9, 10, 12, 255), outline=(186, 113, 54, 255), width=20)
rd.ellipse((cx-70, cy-70, cx+70, cy+70), fill=(33, 34, 37, 255), outline=(222, 226, 229, 230), width=14)

# Three subtle spool cut-outs.
for angle in (-58, 62, 180):
    rad = math.radians(angle)
    px = cx + int(math.cos(rad) * 445)
    py = cy + int(math.sin(rad) * 445)
    w, h = 95, 190
    rd.rounded_rectangle((px-w, py-h//2, px+w, py+h//2), radius=55, fill=(7, 8, 10, 230), outline=(104, 63, 35, 190), width=10)

img = Image.alpha_composite(img, reel)

# Cable/ribbon shadow and amber edge glow.
glow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
gd = ImageDraw.Draw(glow)
gd.line(path, fill=(255, 126, 26, 210), width=252, joint="curve")
glow = glow.filter(ImageFilter.GaussianBlur(58))
img = Image.alpha_composite(img, glow)

shadow = Image.new("RGBA", (S, S), (0, 0, 0, 0))
sd = ImageDraw.Draw(shadow)
sd.line([(x+20, y+32) for x, y in path], fill=(0, 0, 0, 180), width=238, joint="curve")
shadow = shadow.filter(ImageFilter.GaussianBlur(24))
img = Image.alpha_composite(img, shadow)

# Main metallic ribbon: dark bronze edge, ivory-silver body, narrow specular highlight.
ribbon = Image.new("RGBA", (S, S), (0, 0, 0, 0))
d = ImageDraw.Draw(ribbon)
d.line(path, fill=(113, 62, 30, 255), width=232, joint="curve")
d.line(path, fill=(220, 217, 207, 255), width=190, joint="curve")
d.line([(x-8, y-12) for x, y in path], fill=(251, 249, 241, 245), width=54, joint="curve")
d.line([(x+30, y+34) for x, y in path], fill=(126, 128, 132, 135), width=34, joint="curve")
img = Image.alpha_composite(img, ribbon)

# Finish points: deliberately understated, not generic map pins.
finish = Image.new("RGBA", (S, S), (0, 0, 0, 0))
fd = ImageDraw.Draw(finish)
for px, py, size in [(820, 2420, 122), (1280, 1470, 94)]:
    fd.ellipse((px-size, py-size, px+size, py+size), fill=(14, 15, 18, 255), outline=(235, 231, 220, 255), width=24)
    fd.ellipse((px-38, py-38, px+38, py+38), fill=(230, 133, 57, 255))
    fd.ellipse((px-19, py-19, px+19, py+19), fill=(255, 233, 197, 255))
img = Image.alpha_composite(img, finish)

# Soft lower ambient light.
ambient = Image.new("RGBA", (S, S), (0, 0, 0, 0))
ad = ImageDraw.Draw(ambient)
ad.ellipse((260, 2260, 1760, 3260), fill=(224, 92, 22, 32))
ambient = ambient.filter(ImageFilter.GaussianBlur(170))
img = Image.alpha_composite(img, ambient)

img = img.convert("RGB").resize((1024, 1024), Image.Resampling.LANCZOS)
img.save(OUT, "PNG", optimize=True)
print(OUT)
