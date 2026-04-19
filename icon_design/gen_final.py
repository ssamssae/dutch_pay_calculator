"""
Final icon generator — renders master 1024 (F3: Pretendard Black for corner
chars, locked ₩) and exports all iOS AppIcon sizes and Android mipmap sizes.

Apple rule: no alpha channel (transparent pixels cause App Store rejection).
All PNGs written as RGB.
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path

SIZE = 1024
AMBER = (255, 179, 0)
AMBER_DEEP = (230, 145, 0)
AMBER_DOT = (240, 150, 0)
WHITE = (255, 255, 255)

ROOT = Path("/Users/user/dutch_pay_calculator")
OUT = ROOT / "icon_design"

FONT_SDGOTHIC = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
FONT_PRETENDARD_BLACK = "/Users/user/Library/Fonts/Pretendard-Black.otf"

IOS_DIR = ROOT / "ios/Runner/Assets.xcassets/AppIcon.appiconset"
ANDROID_RES = ROOT / "android/app/src/main/res"

# iOS (filename, pixel size)
IOS_SIZES = [
    ("Icon-App-20x20@1x.png", 20),
    ("Icon-App-20x20@2x.png", 40),
    ("Icon-App-20x20@3x.png", 60),
    ("Icon-App-29x29@1x.png", 29),
    ("Icon-App-29x29@2x.png", 58),
    ("Icon-App-29x29@3x.png", 87),
    ("Icon-App-40x40@1x.png", 40),
    ("Icon-App-40x40@2x.png", 80),
    ("Icon-App-40x40@3x.png", 120),
    ("Icon-App-60x60@2x.png", 120),
    ("Icon-App-60x60@3x.png", 180),
    ("Icon-App-76x76@1x.png", 76),
    ("Icon-App-76x76@2x.png", 152),
    ("Icon-App-83.5x83.5@2x.png", 167),
    ("Icon-App-1024x1024@1x.png", 1024),
]

# Android (mipmap dir, pixel size)
ANDROID_SIZES = [
    ("mipmap-mdpi", 48),
    ("mipmap-hdpi", 72),
    ("mipmap-xhdpi", 96),
    ("mipmap-xxhdpi", 144),
    ("mipmap-xxxhdpi", 192),
]


def _center_text(d, cx, cy, text, font, fill):
    bbox = d.textbbox((0, 0), text, font=font, anchor="lt")
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    d.text((cx - w // 2 - bbox[0], cy - h // 2 - bbox[1]),
           text, font=font, fill=fill)


def render_master() -> Image.Image:
    img = Image.new("RGB", (SIZE, SIZE), AMBER)
    cx, cy = SIZE // 2, SIZE // 2
    r = 310

    # coin shadow
    sh = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    shd = ImageDraw.Draw(sh)
    shd.ellipse([cx - r + 10, cy - r + 22, cx + r + 10, cy + r + 22],
                fill=(0, 0, 0, 80))
    sh = sh.filter(ImageFilter.GaussianBlur(18))
    img = Image.alpha_composite(img.convert("RGBA"), sh).convert("RGB")
    d = ImageDraw.Draw(img, "RGBA")

    # white coin
    d.ellipse([cx - r, cy - r, cx + r, cy + r], fill=WHITE)

    # 4 corner chars — Pretendard Black 200
    corner_font = ImageFont.truetype(FONT_PRETENDARD_BLACK, 200)
    pad = 70
    corners = [
        ("더", pad,         pad,         "lt"),
        ("치", SIZE - pad,  pad,         "rt"),
        ("페", pad,         SIZE - pad,  "lb"),
        ("이", SIZE - pad,  SIZE - pad,  "rb"),
    ]
    for ch, x, y, anchor in corners:
        d.text((x, y), ch, font=corner_font, fill=WHITE, anchor=anchor)

    # 3 amber dots inside coin (upper)
    dot_r = 32
    dot_y = cy - 140
    for dx in (-130, 0, 130):
        d.ellipse([cx + dx - dot_r, dot_y - dot_r,
                   cx + dx + dot_r, dot_y + dot_r], fill=AMBER_DOT)

    # ₩ symbol — SDGothic Bold, locked size 380
    won = ImageFont.truetype(FONT_SDGOTHIC, 380, index=7)
    _center_text(d, cx, cy + 60, "₩", won, AMBER_DEEP)

    return img


def resize_rgb(master: Image.Image, size: int) -> Image.Image:
    """High-quality resize, force RGB (strip alpha)."""
    resized = master.resize((size, size), Image.LANCZOS)
    if resized.mode != "RGB":
        resized = resized.convert("RGB")
    return resized


def main():
    master = render_master()
    master_path = OUT / "icon_final_1024.png"
    master.save(master_path, "PNG")
    print(f"master: {master_path}")

    # iOS
    for name, sz in IOS_SIZES:
        out = IOS_DIR / name
        resize_rgb(master, sz).save(out, "PNG")
    print(f"iOS: {len(IOS_SIZES)} files → {IOS_DIR}")

    # Android
    for subdir, sz in ANDROID_SIZES:
        out = ANDROID_RES / subdir / "ic_launcher.png"
        resize_rgb(master, sz).save(out, "PNG")
    print(f"Android: {len(ANDROID_SIZES)} files → {ANDROID_RES}/mipmap-*")


if __name__ == "__main__":
    main()
