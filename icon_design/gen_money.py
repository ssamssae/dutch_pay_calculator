"""
Money-based icon concepts for dutch pay calculator.
Background: dark navy (#16213E) — matches app theme, avoids iOS calc collision.
Foreground: amber (#FFB300) — brand color.

Concepts:
  A) Single banknote with ₩
  B) Stacked 3 banknotes (dutch pay = multiple shares)
  C) Coin stack with ₩ on top
"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

SIZE = 1024
NAVY = (22, 33, 62, 255)
AMBER = (255, 179, 0, 255)
AMBER_DIM = (224, 150, 0, 255)   # back-layer bills
WHITE = (255, 255, 255, 255)
BLACK = (0, 0, 0, 255)

OUT = Path(__file__).parent


def get_font(size, prefer_korean=True):
    paths = [
        "/System/Library/Fonts/AppleSDGothicNeo.ttc",
        "/System/Library/Fonts/HelveticaNeue.ttc",
        "/System/Library/Fonts/Helvetica.ttc",
    ]
    for p in paths:
        try:
            return ImageFont.truetype(p, size)
        except Exception:
            continue
    return ImageFont.load_default()


def rounded_bill(img, cx, cy, w, h, color, radius, tilt=0, outline=None, outline_w=0):
    """Draw a rounded rectangle (banknote) centered at (cx, cy), optionally rotated."""
    layer = Image.new("RGBA", (w + 40, h + 40), (0, 0, 0, 0))
    ld = ImageDraw.Draw(layer)
    ld.rounded_rectangle([20, 20, w + 20, h + 20], radius=radius, fill=color,
                         outline=outline, width=outline_w)
    if tilt != 0:
        layer = layer.rotate(tilt, resample=Image.BICUBIC, expand=True)
    lw, lh = layer.size
    img.alpha_composite(layer, (cx - lw // 2, cy - lh // 2))


def draw_won(img, cx, cy, size, color=NAVY):
    """Draw a crisp ₩ character centered at (cx, cy) at given font size."""
    d = ImageDraw.Draw(img)
    font = get_font(size)
    text = "\u20A9"
    bbox = d.textbbox((0, 0), text, font=font)
    tw = bbox[2] - bbox[0]
    th = bbox[3] - bbox[1]
    d.text((cx - tw // 2 - bbox[0], cy - th // 2 - bbox[1]), text, font=font, fill=color)


# ----- Concept A: single banknote -----
def make_concept_a():
    img = Image.new("RGBA", (SIZE, SIZE), NAVY)
    # banknote
    rounded_bill(img, 512, 512, 720, 440, AMBER, radius=48)
    # inner decorative border
    d = ImageDraw.Draw(img)
    d.rounded_rectangle([512 - 340, 512 - 200, 512 + 340, 512 + 200],
                        radius=30, outline=NAVY, width=8)
    # ₩ centered
    draw_won(img, 512, 512, 320, color=NAVY)
    return img.convert("RGB")


# ----- Concept B: stacked 3 banknotes -----
def make_concept_b():
    img = Image.new("RGBA", (SIZE, SIZE), NAVY)
    # Back bill (most tilted, dimmer)
    rounded_bill(img, 460, 440, 620, 360, AMBER_DIM, radius=36, tilt=-14)
    # Middle bill
    rounded_bill(img, 540, 500, 620, 360, (240, 165, 0, 255), radius=36, tilt=-4)
    # Front bill (brightest, on top)
    rounded_bill(img, 540, 580, 640, 380, AMBER, radius=40, tilt=6)
    # ₩ on the front bill
    draw_won(img, 540, 580, 260, color=NAVY)
    return img.convert("RGB")


# ----- Concept C: coin stack with ₩ -----
def make_concept_c():
    img = Image.new("RGBA", (SIZE, SIZE), NAVY)
    d = ImageDraw.Draw(img)

    # 3 stacked coins (ellipses for perspective)
    # Bottom coin (back)
    cx, cy = 512, 760
    w, h = 520, 130
    d.ellipse([cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2], fill=AMBER_DIM)
    # Middle
    cy = 640
    d.ellipse([cx - w // 2, cy - h // 2, cx + w // 2, cy + h // 2], fill=(240, 165, 0, 255))
    # Top
    cy_top = 460
    d.ellipse([cx - w // 2, cy_top - h // 2, cx + w // 2, cy_top + h // 2], fill=AMBER)
    # Top face (slightly lighter)
    d.ellipse([cx - w // 2, cy_top - h // 2 - 80, cx + w // 2, cy_top + h // 2 - 80],
              fill=AMBER)
    # ₩ on top face
    draw_won(img, cx, cy_top - 80, 200, color=NAVY)
    return img.convert("RGB")


def main():
    configs = [("A_single_bill", make_concept_a),
               ("B_stacked_bills", make_concept_b),
               ("C_coin_stack", make_concept_c)]
    for name, fn in configs:
        img = fn()
        img.save(OUT / f"concept_{name}.png", "PNG")
    # Small previews strip
    strip = Image.new("RGB", (120 * 3 + 80, 180), (20, 20, 20))
    for i, (name, _) in enumerate(configs):
        p = Image.open(OUT / f"concept_{name}.png").resize((120, 120), Image.LANCZOS)
        strip.paste(p, (20 + i * (120 + 20), (180 - 120) // 2))
    strip.save(OUT / "concepts_preview.png")
    print("wrote:", sorted(p.name for p in OUT.glob("concept_*.png")))


if __name__ == "__main__":
    main()
