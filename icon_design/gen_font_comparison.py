"""
더치페이 corner-char font comparison.
Base layout: centered coin + amber ₩ (size LOCKED) + 4 corner chars.
Vary only the corner-char font. Generate 6 candidates.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path

SIZE = 1024
AMBER = (255, 179, 0)
AMBER_DEEP = (230, 145, 0)
AMBER_DOT = (240, 150, 0)
WHITE = (255, 255, 255)

OUT = Path(__file__).parent
FONT_SDGOTHIC = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
FONT_APPLE_GOTHIC = "/System/Library/Fonts/Supplemental/AppleGothic.ttf"
FONT_MYUNGJO = "/System/Library/Fonts/Supplemental/AppleMyungjo.ttf"
FONT_PRETENDARD_BLACK = "/Users/user/Library/Fonts/Pretendard-Black.otf"
FONT_PRETENDARD_BOLD = "/Users/user/Library/Fonts/Pretendard-Bold.otf"
FONT_PRETENDARD_EXTRA = "/Users/user/Library/Fonts/Pretendard-ExtraBold.otf"

# Locked ₩ parameters (user requested: DO NOT shrink ₩)
WON_FONT_SIZE = 380
WON_Y_OFFSET = 60  # relative to center


def _center_text(d, cx, cy, text, font, fill):
    bbox = d.textbbox((0, 0), text, font=font, anchor="lt")
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    d.text((cx - w // 2 - bbox[0], cy - h // 2 - bbox[1]),
           text, font=font, fill=fill)


def _coin(img, cx, cy, r):
    sh = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shd = ImageDraw.Draw(sh)
    shd.ellipse([cx - r + 10, cy - r + 22, cx + r + 10, cy + r + 22],
                fill=(0, 0, 0, 80))
    sh = sh.filter(ImageFilter.GaussianBlur(18))
    img = Image.alpha_composite(img.convert("RGBA"), sh).convert("RGB")
    d = ImageDraw.Draw(img, "RGBA")
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=WHITE)
    return img


def build_icon(corner_font_path, corner_size=200, font_index=0, label="?"):
    img = Image.new("RGB", (SIZE, SIZE), AMBER)
    cx, cy = SIZE // 2, SIZE // 2
    r = 310
    img = _coin(img, cx, cy, r)
    d = ImageDraw.Draw(img, "RGBA")

    # 4 corner chars — bigger
    if font_index is not None and corner_font_path.endswith(".ttc"):
        corner_font = ImageFont.truetype(corner_font_path, corner_size,
                                         index=font_index)
    else:
        corner_font = ImageFont.truetype(corner_font_path, corner_size)

    pad = 70
    corners = [
        ("더", pad,         pad,         "lt"),
        ("치", SIZE - pad,  pad,         "rt"),
        ("페", pad,         SIZE - pad,  "lb"),
        ("이", SIZE - pad,  SIZE - pad,  "rb"),
    ]
    for ch, x, y, anchor in corners:
        d.text((x, y), ch, font=corner_font, fill=WHITE, anchor=anchor)

    # 3 dots + ₩ (LOCKED size)
    dot_r = 32
    dot_y = cy - 140
    for dx in (-130, 0, 130):
        d.ellipse([cx + dx - dot_r, dot_y - dot_r,
                   cx + dx + dot_r, dot_y + dot_r], fill=AMBER_DOT)
    won = ImageFont.truetype(FONT_SDGOTHIC, WON_FONT_SIZE, index=7)
    _center_text(d, cx, cy + WON_Y_OFFSET, "₩", won, AMBER_DEEP)

    return img


def main():
    configs = [
        ("F1", FONT_SDGOTHIC, 200, 7, "F1  애플 SD 고딕 Bold (현재)"),
        ("F2", FONT_SDGOTHIC, 200, 9, "F2  애플 SD 고딕 Heavy"),
        ("F3", FONT_PRETENDARD_BLACK, 200, None, "F3  Pretendard Black"),
        ("F4", FONT_PRETENDARD_BOLD, 200, None, "F4  Pretendard Bold"),
        ("F5", FONT_APPLE_GOTHIC, 200, None, "F5  Apple Gothic (레트로)"),
        ("F6", FONT_MYUNGJO, 200, None, "F6  Apple Myungjo (명조)"),
    ]

    imgs = []
    labels = []
    for key, path, size, idx, label in configs:
        im = build_icon(path, size, idx, label)
        im.save(OUT / f"won_font_{key}.png", "PNG")
        imgs.append(im)
        labels.append(label)

    # 3x2 preview grid
    cell = 480
    pad = 24
    label_h = 54
    cols = 3
    rows = 2
    W = cell * cols + pad * (cols + 1)
    H = (cell + label_h) * rows + pad * (rows + 1)
    grid = Image.new("RGB", (W, H), (20, 20, 25))
    d = ImageDraw.Draw(grid)
    font = ImageFont.truetype(FONT_SDGOTHIC, 26, index=7)
    for i, (im, lbl) in enumerate(zip(imgs, labels)):
        r, c = divmod(i, cols)
        x = pad + c * (cell + pad)
        y = pad + r * (cell + label_h + pad)
        thumb = im.resize((cell, cell), Image.LANCZOS)
        grid.paste(thumb, (x, y))
        d.text((x + 12, y + cell + 12), lbl, fill=WHITE, font=font)
    grid.save(OUT / "font_comparison_preview.png", "PNG")
    print("generated:", [p.name for p in sorted(OUT.glob("won_font_*.png"))])


if __name__ == "__main__":
    main()
