"""
6 won-symbol style variants on 1024 amber background.
Focus: only the ₩ mark — user will pick the style they like.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path

SIZE = 1024
AMBER = (255, 179, 0)
AMBER_DEEP = (230, 145, 0)
DARK = (17, 24, 39)
WHITE = (255, 255, 255)

OUT = Path(__file__).parent

FONT_SDGOTHIC = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
FONT_ARIAL_BLACK = "/System/Library/Fonts/Supplemental/Arial Black.ttf"
FONT_ARIAL_BOLD = "/System/Library/Fonts/Supplemental/Arial Bold.ttf"
FONT_HELV = "/System/Library/Fonts/Helvetica.ttc"


def _center_text(d, cx, cy, text, font, fill):
    bbox = d.textbbox((0, 0), text, font=font, anchor="lt")
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    d.text((cx - w // 2 - bbox[0], cy - h // 2 - bbox[1]),
           text, font=font, fill=fill)


def _bg_amber():
    img = Image.new("RGB", (SIZE, SIZE), AMBER)
    return img


# ──────────────────────────────────────────────
# Style 1 — Typographic ₩ (Apple SD Gothic Neo Bold)
# Uses the actual ₩ glyph from Apple font — clean, KR-native feel.
# ──────────────────────────────────────────────
def style_1():
    img = _bg_amber()
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT_SDGOTHIC, 820, index=7)  # bold
    _center_text(d, SIZE // 2, SIZE // 2 + 20, "₩", font, WHITE)
    return img


# ──────────────────────────────────────────────
# Style 2 — Lighter weight ₩ (Apple SD Gothic Neo Regular) — airy
# ──────────────────────────────────────────────
def style_2():
    img = _bg_amber()
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT_SDGOTHIC, 820, index=2)  # regular
    _center_text(d, SIZE // 2, SIZE // 2 + 20, "₩", font, WHITE)
    return img


# ──────────────────────────────────────────────
# Style 3 — Coin style: white circle + bold ₩ inside (Toss-esque)
# ──────────────────────────────────────────────
def style_3():
    img = _bg_amber()
    d = ImageDraw.Draw(img, "RGBA")
    cx, cy = SIZE // 2, SIZE // 2
    r = 380
    sh = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shd = ImageDraw.Draw(sh)
    shd.ellipse([cx - r + 10, cy - r + 22, cx + r + 10, cy + r + 22],
                fill=(0, 0, 0, 80))
    sh = sh.filter(ImageFilter.GaussianBlur(18))
    img = Image.alpha_composite(img.convert("RGBA"), sh).convert("RGB")
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=WHITE)
    font = ImageFont.truetype(FONT_SDGOTHIC, 580, index=7)
    _center_text(d, cx, cy + 20, "₩", font, AMBER_DEEP)
    return img


# ──────────────────────────────────────────────
# Style 4 — Outlined ₩ using PIL stroke_width (clean single-glyph stroke)
# ──────────────────────────────────────────────
def style_4():
    img = _bg_amber()
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT_SDGOTHIC, 820, index=7)
    bbox = d.textbbox((0, 0), "₩", font=font, anchor="lt")
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    tx = SIZE // 2 - w // 2 - bbox[0]
    ty = SIZE // 2 + 20 - h // 2 - bbox[1]
    d.text((tx, ty), "₩", font=font, fill=AMBER,
           stroke_width=22, stroke_fill=WHITE)
    return img


# ──────────────────────────────────────────────
# Style 5 — Geometric ₩ built from rectangles (sharp, no rounded)
# ──────────────────────────────────────────────
def style_5():
    img = _bg_amber()
    d = ImageDraw.Draw(img)
    cx, cy = SIZE // 2, SIZE // 2
    # W made of 4 sharp diagonal bars
    stroke = 90
    top_y = cy - 260
    bot_y = cy + 260
    peak_y = cy + 100
    pts = [
        (cx - 340, top_y),
        (cx - 180, bot_y),
        (cx,       peak_y),
        (cx + 180, bot_y),
        (cx + 340, top_y),
    ]

    def sharp_line(p1, p2, w):
        # compute perpendicular offsets
        import math
        x1, y1 = p1
        x2, y2 = p2
        dx, dy = x2 - x1, y2 - y1
        length = math.hypot(dx, dy)
        ux, uy = -dy / length, dx / length
        hw = w / 2
        poly = [
            (x1 + ux * hw, y1 + uy * hw),
            (x2 + ux * hw, y2 + uy * hw),
            (x2 - ux * hw, y2 - uy * hw),
            (x1 - ux * hw, y1 - uy * hw),
        ]
        d.polygon(poly, fill=WHITE)

    for p1, p2 in zip(pts, pts[1:]):
        sharp_line(p1, p2, stroke)

    # sharp double bars — short, tucked inside the W span (mid-height)
    bar_h = 44
    bar_x0, bar_x1 = cx - 220, cx + 220
    for by in (cy - 60, cy + 20):
        d.rectangle([bar_x0, by - bar_h // 2, bar_x1, by + bar_h // 2],
                    fill=WHITE)
    return img


# ──────────────────────────────────────────────
# Style 6 — ₩ with divide dots above (두 사람이 나누는 느낌)
# Typographic ₩ + 2 dots on each side = subtle "splitting" metaphor
# ──────────────────────────────────────────────
def style_6():
    img = _bg_amber()
    d = ImageDraw.Draw(img)
    font = ImageFont.truetype(FONT_SDGOTHIC, 680, index=7)
    _center_text(d, SIZE // 2, SIZE // 2 + 80, "₩", font, WHITE)
    # 3 dots above — people being split
    dot_r = 36
    for dx in (-180, 0, 180):
        d.ellipse([SIZE // 2 + dx - dot_r, 180 - dot_r,
                   SIZE // 2 + dx + dot_r, 180 + dot_r], fill=WHITE)
    return img


def make_preview(imgs, labels, path):
    cell = 480
    pad = 24
    label_h = 54
    cols = 3
    rows = 2
    W = cell * cols + pad * (cols + 1)
    H = (cell + label_h) * rows + pad * (rows + 1)
    grid = Image.new("RGB", (W, H), (20, 20, 25))
    d = ImageDraw.Draw(grid)
    try:
        font = ImageFont.truetype(FONT_SDGOTHIC, 26, index=7)
    except Exception:
        font = ImageFont.load_default()
    for i, (im, lbl) in enumerate(zip(imgs, labels)):
        r, c = divmod(i, cols)
        x = pad + c * (cell + pad)
        y = pad + r * (cell + label_h + pad)
        thumb = im.resize((cell, cell), Image.LANCZOS)
        grid.paste(thumb, (x, y))
        d.text((x + 12, y + cell + 12), lbl, fill=WHITE, font=font)
    grid.save(path, "PNG")


def main():
    styles = [
        ("1", style_1, "1  타이포 ₩ (한국 고딕)"),
        ("2", style_2, "2  라이트 ₩ (에어리 톤)"),
        ("3", style_3, "3  코인 (동그라미 + ₩)"),
        ("4", style_4, "4  아웃라인 ₩"),
        ("5", style_5, "5  샤프 지오메트릭 ₩"),
        ("6", style_6, "6  ₩ + 3명 점"),
    ]
    imgs = []
    labels = []
    for key, fn, label in styles:
        im = fn()
        im.save(OUT / f"won_style_{key}.png", "PNG")
        imgs.append(im)
        labels.append(label)
    make_preview(imgs, labels, OUT / "won_styles_preview.png")
    print("generated:", sorted(p.name for p in OUT.glob("won_style_*.png")))


if __name__ == "__main__":
    main()
