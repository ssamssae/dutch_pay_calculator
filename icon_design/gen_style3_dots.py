"""
Style 3 (white coin + amber ₩) + 3 amber dots.
Two placements to choose from:
  A  dots INSIDE coin, above ₩   (original dutch-pay icon layout, but in coin)
  B  dots ABOVE coin on amber bg, slightly darker for contrast
Saves won_style_3a.png, won_style_3b.png, and a side-by-side preview.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path

SIZE = 1024
AMBER = (255, 179, 0)
AMBER_DEEP = (230, 145, 0)
AMBER_DOT = (240, 150, 0)
WHITE = (255, 255, 255)

FONT_SDGOTHIC = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
OUT = Path(__file__).parent


def _center_text(d, cx, cy, text, font, fill):
    bbox = d.textbbox((0, 0), text, font=font, anchor="lt")
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    d.text((cx - w // 2 - bbox[0], cy - h // 2 - bbox[1]),
           text, font=font, fill=fill)


def _coin(img, cx, cy, r):
    # drop shadow
    sh = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shd = ImageDraw.Draw(sh)
    shd.ellipse([cx - r + 10, cy - r + 22, cx + r + 10, cy + r + 22],
                fill=(0, 0, 0, 80))
    sh = sh.filter(ImageFilter.GaussianBlur(18))
    img = Image.alpha_composite(img.convert("RGBA"), sh).convert("RGB")
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=WHITE)
    return img


def variant_A():
    """Centered coin, 3 dots + ₩ balanced inside, 더/치/페/이 in 4 corners."""
    img = Image.new("RGB", (SIZE, SIZE), AMBER)
    cx, cy = SIZE // 2, SIZE // 2
    r = 310  # shrink so corner chars have clearance
    img = _coin(img, cx, cy, r)
    d = ImageDraw.Draw(img, "RGBA")

    # 4 Korean chars in corners (white on amber)
    corner_font = ImageFont.truetype(FONT_SDGOTHIC, 160, index=7)
    pad = 80
    corners = [
        ("더", pad,         pad,         "lt"),
        ("치", SIZE - pad,  pad,         "rt"),
        ("페", pad,         SIZE - pad,  "lb"),
        ("이", SIZE - pad,  SIZE - pad,  "rb"),
    ]
    for ch, x, y, anchor in corners:
        d.text((x, y), ch, font=corner_font, fill=WHITE, anchor=anchor)

    # 3 dots + ₩ inside coin
    dot_r = 32
    dot_y = cy - 140
    for dx in (-130, 0, 130):
        d.ellipse([cx + dx - dot_r, dot_y - dot_r,
                   cx + dx + dot_r, dot_y + dot_r], fill=AMBER_DOT)

    font = ImageFont.truetype(FONT_SDGOTHIC, 380, index=7)
    _center_text(d, cx, cy + 60, "₩", font, AMBER_DEEP)
    return img


def variant_B():
    """Dots above the coin on amber bg, slightly darker amber."""
    img = Image.new("RGB", (SIZE, SIZE), AMBER)
    cx, cy = SIZE // 2, SIZE // 2 + 80
    r = 340
    img = _coin(img, cx, cy, r)
    d = ImageDraw.Draw(img, "RGBA")

    # 3 darker amber dots on amber bg above coin
    dot_r = 46
    dot_y = 180
    dark_dot = (200, 125, 0)
    for dx in (-160, 0, 160):
        d.ellipse([cx + dx - dot_r, dot_y - dot_r,
                   cx + dx + dot_r, dot_y + dot_r], fill=dark_dot)

    font = ImageFont.truetype(FONT_SDGOTHIC, 520, index=7)
    _center_text(d, cx, cy + 20, "₩", font, AMBER_DEEP)
    return img


def make_preview(imgs, labels, path):
    cell = 520
    pad = 24
    label_h = 54
    W = cell * 2 + pad * 3
    H = cell + label_h + pad * 2
    grid = Image.new("RGB", (W, H), (20, 20, 25))
    d = ImageDraw.Draw(grid)
    font = ImageFont.truetype(FONT_SDGOTHIC, 26, index=7)
    for i, (im, lbl) in enumerate(zip(imgs, labels)):
        x = pad + i * (cell + pad)
        y = pad
        thumb = im.resize((cell, cell), Image.LANCZOS)
        grid.paste(thumb, (x, y))
        d.text((x + 12, y + cell + 12), lbl, fill=WHITE, font=font)
    grid.save(path, "PNG")


def main():
    a = variant_A()
    b = variant_B()
    a.save(OUT / "won_style_3a.png", "PNG")
    b.save(OUT / "won_style_3b.png", "PNG")
    make_preview([a, b],
                 ["3A  점 코인 안쪽 (위, 노란점)",
                  "3B  점 코인 바깥 (위, 진한 노란점)"],
                 OUT / "style3_dots_preview.png")
    print("generated: won_style_3a.png, won_style_3b.png, style3_dots_preview.png")


if __name__ == "__main__":
    main()
