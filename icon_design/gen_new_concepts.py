"""
New dutch pay icon concepts (4 variations), each 1024x1024 RGB, no alpha.
Outputs: concept_new_A/B/C/D.png + concepts_new_preview.png (2x2 grid).
"""
from PIL import Image, ImageDraw, ImageFilter, ImageFont
from pathlib import Path

SIZE = 1024
OUT = Path(__file__).parent

AMBER = (255, 179, 0)
AMBER_DEEP = (255, 160, 0)
DARK = (17, 24, 39)
DARK_SOFT = (30, 41, 59)
WHITE = (255, 255, 255)
CREAM = (255, 247, 220)
SHADOW = (0, 0, 0, 60)


def _rline(d, p1, p2, width, fill=WHITE):
    d.line([p1, p2], fill=fill, width=width)
    for (x, y) in (p1, p2):
        d.ellipse([x - width // 2, y - width // 2,
                   x + width // 2, y + width // 2], fill=fill)


def _won_symbol(d, cx, cy, h=520, stroke=80, color=WHITE):
    """Hand-drawn double-bar ₩ centered at (cx, cy). h = total height."""
    half = h // 2
    top = cy - half
    bot = cy + half
    span = int(h * 1.1)
    left = cx - span // 2
    right = cx + span // 2
    peak_y = cy + int(h * 0.05)
    b_x = cx - span // 4
    q_x = cx + span // 4

    pts = [
        (left,  top),
        (b_x,   bot),
        (cx,    peak_y),
        (q_x,   bot),
        (right, top),
    ]
    for p1, p2 in zip(pts, pts[1:]):
        _rline(d, p1, p2, stroke, color)

    # double bars in upper third
    bar_w = max(int(stroke * 0.55), 6)
    bar_x0 = left - int(span * 0.08)
    bar_x1 = right + int(span * 0.08)
    offset = int(h * 0.13)
    for by_pos in (top + int(h * 0.13), top + int(h * 0.26)):
        d.rounded_rectangle(
            [bar_x0, by_pos - bar_w // 2, bar_x1, by_pos + bar_w // 2],
            radius=bar_w // 2, fill=color,
        )


# ─────────────────────────────────────────────────────────
# Concept A — Dark bg + amber circle + white ₩ (memoyo style)
# ─────────────────────────────────────────────────────────
def concept_A():
    img = Image.new("RGB", (SIZE, SIZE), DARK)
    d = ImageDraw.Draw(img, "RGBA")

    # subtle gradient via overlay
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for i in range(SIZE):
        a = int(40 * (i / SIZE))
        od.line([(0, i), (SIZE, i)], fill=(10, 15, 30, a))
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    d = ImageDraw.Draw(img, "RGBA")

    # amber circle
    r = 360
    cx, cy = SIZE // 2, SIZE // 2 - 20
    # glow
    glow = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    gd = ImageDraw.Draw(glow)
    gd.ellipse([cx - r - 60, cy - r - 60, cx + r + 60, cy + r + 60],
               fill=(255, 179, 0, 80))
    glow = glow.filter(ImageFilter.GaussianBlur(40))
    img = Image.alpha_composite(img.convert("RGBA"), glow).convert("RGB")
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=AMBER)

    # white ₩ inside
    _won_symbol(d, cx, cy, h=440, stroke=72, color=WHITE)

    # three dots below (split people)
    dot_y = cy + r + 110
    dot_r = 28
    for dx in (-120, 0, 120):
        d.ellipse([cx + dx - dot_r, dot_y - dot_r,
                   cx + dx + dot_r, dot_y + dot_r], fill=AMBER)

    return img


# ─────────────────────────────────────────────────────────
# Concept B — Amber bg + split receipt (영수증 반으로 나뉨)
# ─────────────────────────────────────────────────────────
def concept_B():
    img = Image.new("RGB", (SIZE, SIZE), AMBER)
    d = ImageDraw.Draw(img, "RGBA")

    # subtle top-to-bottom amber gradient
    overlay = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for i in range(SIZE):
        a = int(25 * (i / SIZE))
        od.line([(0, i), (SIZE, i)], fill=(200, 120, 0, a))
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    d = ImageDraw.Draw(img, "RGBA")

    # Two receipt halves, tilted apart
    def receipt(center, angle, total=5):
        tile = Image.new("RGBA", (520, 700), (0, 0, 0, 0))
        td = ImageDraw.Draw(tile)
        # shadow
        sh = Image.new("RGBA", (540, 720), (0, 0, 0, 0))
        shd = ImageDraw.Draw(sh)
        shd.rounded_rectangle([20, 20, 520, 700], radius=16, fill=(0, 0, 0, 90))
        sh = sh.filter(ImageFilter.GaussianBlur(14))
        tile2 = Image.new("RGBA", (540, 720), (0, 0, 0, 0))
        tile2.alpha_composite(sh, (0, 0))
        # body
        td2 = ImageDraw.Draw(tile2)
        td2.rounded_rectangle([20, 0, 520, 680], radius=14, fill=WHITE)
        # zigzag tear at right edge
        teeth = 18
        step = 680 / teeth
        for i in range(teeth + 1):
            y = int(i * step)
            if i % 2 == 0:
                td2.polygon([(520, y), (560, y + step / 2), (520, y + step)],
                            fill=WHITE)
        # content lines
        td2.rectangle([70, 60, 470, 100], fill=(40, 40, 40))     # title
        for i, yy in enumerate((160, 220, 280, 340, 400)):
            td2.rectangle([70, yy, 420 - i * 30, yy + 20], fill=(100, 100, 100))
            td2.rectangle([430 - i * 12, yy, 470, yy + 20], fill=(100, 100, 100))
        # total
        td2.rectangle([70, 500, 260, 540], fill=(40, 40, 40))
        # ₩ mark
        _won_symbol(td2, 370, 585, h=120, stroke=20, color=AMBER_DEEP)
        rot = tile2.rotate(angle, resample=Image.BICUBIC, expand=True)
        img.paste(rot, (center[0] - rot.width // 2, center[1] - rot.height // 2), rot)

    # left half tilted left, right half tilted right
    receipt((330, 540), 10)
    receipt((720, 500), -12)

    return img


# ─────────────────────────────────────────────────────────
# Concept C — Amber bg + 3 coins splitting (동전 3개로 나뉨)
# ─────────────────────────────────────────────────────────
def concept_C():
    img = Image.new("RGB", (SIZE, SIZE), AMBER)

    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    d = ImageDraw.Draw(layer)

    # One big coin splits into 3 smaller — arrange in triangle
    def coin(cx, cy, r, face=WHITE, edge=AMBER_DEEP, won=True):
        # shadow
        sh = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
        shd = ImageDraw.Draw(sh)
        shd.ellipse([cx - r + 14, cy - r + 18, cx + r + 14, cy + r + 18],
                    fill=(0, 0, 0, 110))
        sh = sh.filter(ImageFilter.GaussianBlur(18))
        layer.alpha_composite(sh)
        # body (outer ring)
        d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=edge + (255,))
        inner_r = int(r * 0.86)
        d.ellipse([cx - inner_r, cy - inner_r, cx + inner_r, cy + inner_r],
                  fill=face + (255,))
        if won:
            _won_symbol(d, cx, cy, h=int(r * 1.1), stroke=int(r * 0.18),
                        color=edge)

    # top coin
    coin(512, 340, 200)
    # bottom-left, bottom-right
    coin(300, 700, 200)
    coin(724, 700, 200)

    img = Image.alpha_composite(img.convert("RGBA"), layer).convert("RGB")
    return img


# ─────────────────────────────────────────────────────────
# Concept D — Amber bg + ₩ with subtle divide (÷) mark
# ─────────────────────────────────────────────────────────
def concept_D():
    img = Image.new("RGB", (SIZE, SIZE), AMBER)
    d = ImageDraw.Draw(img, "RGBA")

    # soft rounded square mask to look "iOS native"
    # but keep amber square — rely on OS masking
    # diagonal accent stripe
    stripe = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    sd = ImageDraw.Draw(stripe)
    sd.polygon([(0, 780), (SIZE, 560), (SIZE, 640), (0, 860)],
               fill=(255, 140, 0, 140))
    img = Image.alpha_composite(img.convert("RGBA"), stripe).convert("RGB")
    d = ImageDraw.Draw(img, "RGBA")

    cx, cy = SIZE // 2, SIZE // 2 + 40
    _won_symbol(d, cx, cy, h=560, stroke=90, color=WHITE)

    # divide symbol (÷) above ₩ — small
    dot_r = 26
    bar_y = 220
    d.ellipse([cx - dot_r, bar_y - 70 - dot_r,
               cx + dot_r, bar_y - 70 + dot_r], fill=WHITE)
    d.rounded_rectangle([cx - 90, bar_y - 12, cx + 90, bar_y + 12],
                        radius=12, fill=WHITE)
    d.ellipse([cx - dot_r, bar_y + 70 - dot_r,
               cx + dot_r, bar_y + 70 + dot_r], fill=WHITE)

    return img


def make_preview(imgs, path, labels):
    cell = 480
    pad = 24
    label_h = 52
    W = cell * 2 + pad * 3
    H = (cell + label_h) * 2 + pad * 3
    grid = Image.new("RGB", (W, H), (20, 20, 25))
    d = ImageDraw.Draw(grid)
    try:
        font = ImageFont.truetype(
            "/System/Library/Fonts/Supplemental/AppleSDGothicNeo.ttc", 28)
    except Exception:
        font = ImageFont.load_default()
    for i, (im, lbl) in enumerate(zip(imgs, labels)):
        r, c = divmod(i, 2)
        x = pad + c * (cell + pad)
        y = pad + r * (cell + label_h + pad)
        thumb = im.resize((cell, cell), Image.LANCZOS)
        grid.paste(thumb, (x, y))
        d.text((x + 12, y + cell + 10), lbl, fill=WHITE, font=font)
    grid.save(path, "PNG")


def main():
    imgs = {
        "A": concept_A(),
        "B": concept_B(),
        "C": concept_C(),
        "D": concept_D(),
    }
    for k, im in imgs.items():
        im.save(OUT / f"concept_new_{k}.png", "PNG")
    labels = [
        "A  다크 + 노란 ₩ (메모요 톤)",
        "B  영수증 반으로 나뉨",
        "C  동전 3개 나눔",
        "D  ₩ + 나누기(÷) 심볼",
    ]
    make_preview([imgs["A"], imgs["B"], imgs["C"], imgs["D"]],
                 OUT / "concepts_new_preview.png", labels)
    print("generated:", sorted(p.name for p in OUT.glob("concept_new_*.png")))


if __name__ == "__main__":
    main()
