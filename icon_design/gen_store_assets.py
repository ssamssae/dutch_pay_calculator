"""
Generate store promo assets for 더치페이 계산기.

Outputs:
- icon_512.png (512x512)
- feature_graphic.png (1024x500, Play feature graphic)
- screenshot_*.png (1080x1920, Play portrait screenshots)
- app_store_6_9_screenshot_*.png (1320x2868, iOS 6.9 screenshots)
"""
from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT / "icon_design" / "store_assets"
OUT.mkdir(parents=True, exist_ok=True)

MASTER = ROOT / "icon_design" / "icon3_master.png"

BG_DEEP = (10, 20, 34)
BG_BLACK = (5, 8, 15)
SURFACE = (19, 32, 58)
SURFACE_ELEVATED = (26, 45, 74)
TEAL = (61, 224, 200)
TEAL_DARK = (20, 156, 147)
TEXT_PRIMARY = (245, 247, 250)
TEXT_SECONDARY = (138, 152, 176)
WHITE = (255, 255, 255)
BLUE = (86, 151, 255)
VIOLET = (148, 103, 255)

FONT_SDGOTHIC = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
FONT_PRETENDARD_BLACK = "/Users/user/Library/Fonts/Pretendard-Black.otf"


def _font(path, size, index=0):
    try:
        return ImageFont.truetype(path, size, index=index)
    except OSError:
        return ImageFont.truetype(FONT_SDGOTHIC, size, index=7)


def _center_text(d, cx, cy, text, font, fill):
    bbox = d.textbbox((0, 0), text, font=font, anchor="lt")
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    d.text((cx - w // 2 - bbox[0], cy - h // 2 - bbox[1]), text, font=font, fill=fill)


def _linear_gradient(size, top, bottom):
    w, h = size
    img = Image.new("RGB", size, top)
    d = ImageDraw.Draw(img)
    for y in range(h):
        t = y / max(h - 1, 1)
        color = tuple(int(top[i] * (1 - t) + bottom[i] * t) for i in range(3))
        d.line([(0, y), (w, y)], fill=color)
    return img


def _glow(img, center, radius, color, alpha=80):
    layer = Image.new("RGBA", img.size, (0, 0, 0, 0))
    d = ImageDraw.Draw(layer, "RGBA")
    x, y = center
    d.ellipse([x - radius, y - radius, x + radius, y + radius], fill=(*color, alpha))
    layer = layer.filter(ImageFilter.GaussianBlur(radius // 2))
    img.alpha_composite(layer)


def _paste_icon(img, box, radius=54):
    raw = Image.open(MASTER).convert("RGBA")
    trim = max(1, raw.width // 24)
    icon = raw.crop((trim, trim, raw.width - trim, raw.height - trim))
    icon = icon.resize((box[2] - box[0], box[3] - box[1]), Image.LANCZOS)
    mask = Image.new("L", icon.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle([0, 0, icon.width, icon.height], radius=radius, fill=255)
    icon.putalpha(mask)
    plate = Image.new("RGBA", img.size, (0, 0, 0, 0))
    pd = ImageDraw.Draw(plate, "RGBA")
    pd.rounded_rectangle(box, radius=radius, fill=(255, 255, 255, 245))
    plate.alpha_composite(icon, (box[0], box[1]))
    img.alpha_composite(plate)


def _draw_header_band(img, h):
    d = ImageDraw.Draw(img, "RGBA")
    d.rounded_rectangle([0, 0, img.width, h + 60], radius=0, fill=(*TEAL_DARK, 255))
    band = _linear_gradient((img.width, h + 60), TEAL, TEAL_DARK).convert("RGBA")
    img.alpha_composite(band, (0, 0))
    _glow(img, (int(img.width * 0.82), 80), int(img.width * 0.18), WHITE, alpha=38)
    d.line([(0, h + 58), (img.width, h + 58)], fill=(*TEAL, 70), width=2)


def _draw_mock_calculator(d, scale, x, y, w):
    r = int(40 * scale)
    h = int(610 * scale)
    d.rounded_rectangle([x, y, x + w, y + h], radius=r, fill=(*SURFACE, 238), outline=(*TEAL, 58), width=max(1, int(2 * scale)))

    label_font = _font(FONT_SDGOTHIC, int(42 * scale), index=7)
    value_font = _font(FONT_PRETENDARD_BLACK, int(58 * scale))
    cta_font = _font(FONT_PRETENDARD_BLACK, int(52 * scale))
    small_font = _font(FONT_SDGOTHIC, int(31 * scale), index=7)

    pad = int(60 * scale)
    row_w = w - pad * 2

    d.text((x + pad, y + int(58 * scale)), "총 금액", font=label_font, fill=TEXT_SECONDARY)
    d.rounded_rectangle([x + pad, y + int(122 * scale), x + pad + row_w, y + int(218 * scale)],
                        radius=int(18 * scale), fill=(*SURFACE_ELEVATED, 255))
    _center_text(d, x + w // 2, y + int(170 * scale), "120,000 원", value_font, TEXT_PRIMARY)

    d.text((x + pad, y + int(265 * scale)), "인원수", font=label_font, fill=TEXT_SECONDARY)
    d.rounded_rectangle([x + pad, y + int(330 * scale), x + pad + row_w, y + int(426 * scale)],
                        radius=int(18 * scale), fill=(*SURFACE_ELEVATED, 255))
    _center_text(d, x + w // 2, y + int(378 * scale), "5 명", value_font, TEXT_PRIMARY)

    cta_y = y + int(482 * scale)
    d.rounded_rectangle([x + pad, cta_y, x + pad + row_w, cta_y + int(116 * scale)],
                        radius=int(26 * scale), fill=(*TEAL, 255))
    _center_text(d, x + w // 2, cta_y + int(58 * scale), "1인당 24,000원", cta_font, BG_DEEP)
    d.text((x + pad, cta_y - int(32 * scale)), "나머지 0원 · 바로 공유", font=small_font, fill=(*TEXT_SECONDARY, 230))


def icon_512():
    im = Image.open(MASTER).convert("RGB")
    im.resize((512, 512), Image.LANCZOS).save(OUT / "icon_512.png", "PNG", optimize=True)


def feature_graphic():
    img = _linear_gradient((1024, 500), BG_DEEP, BG_BLACK).convert("RGBA")
    d = ImageDraw.Draw(img, "RGBA")
    _glow(img, (820, 70), 230, TEAL, 68)
    _glow(img, (140, 450), 190, BLUE, 42)

    d.rounded_rectangle([58, 70, 366, 430], radius=42, fill=(*SURFACE, 225), outline=(*TEAL, 58), width=2)
    _paste_icon(img, [92, 96, 332, 336], radius=42)
    pill_font = _font(FONT_SDGOTHIC, 27, index=7)
    d.rounded_rectangle([116, 360, 308, 402], radius=21, fill=(*SURFACE_ELEVATED, 255), outline=(*TEAL, 92), width=1)
    _center_text(d, 212, 381, "빠른 정산", pill_font, TEAL)

    title_font = _font(FONT_PRETENDARD_BLACK, 82)
    sub_font = _font(FONT_SDGOTHIC, 37, index=7)
    d.text((430, 118), "더치페이 계산기", font=title_font, fill=TEXT_PRIMARY)
    d.text((434, 235), "여럿이 먹은 자리, 깔끔하게 N분의 1", font=sub_font, fill=(*TEXT_SECONDARY, 255))
    d.rounded_rectangle([434, 322, 770, 388], radius=33, fill=(*TEAL, 255))
    _center_text(d, 602, 354, "금액 + 인원수만 입력", _font(FONT_SDGOTHIC, 29, index=7), BG_DEEP)

    img.convert("RGB").save(OUT / "feature_graphic.png", "PNG", optimize=True)


def promo_screenshot(idx, title, subtitle, size=(1080, 1920), out_name=None):
    w, h = size
    scale = w / 1080
    yscale = h / 1920
    img = _linear_gradient(size, BG_DEEP, BG_BLACK).convert("RGBA")
    d = ImageDraw.Draw(img, "RGBA")
    _glow(img, (int(w * 0.78), int(h * 0.18)), int(w * 0.35), TEAL, 54)
    _glow(img, (int(w * 0.18), int(h * 0.68)), int(w * 0.34), VIOLET, 38)

    header_h = int(260 * yscale)
    _draw_header_band(img, header_h)
    title_font = _font(FONT_PRETENDARD_BLACK, int(72 * scale))
    _center_text(d, w // 2, int(140 * yscale), "더치페이 계산기", title_font, BG_DEEP)

    icon_size = int(330 * scale)
    icon_y = int(425 * yscale)
    _paste_icon(img, [(w - icon_size) // 2, icon_y, (w + icon_size) // 2, icon_y + icon_size], radius=int(58 * scale))

    feat_font = _font(FONT_PRETENDARD_BLACK, int(76 * scale))
    sub_font = _font(FONT_SDGOTHIC, int(46 * scale), index=7)
    _center_text(d, w // 2, int(900 * yscale), title, feat_font, TEAL)
    _center_text(d, w // 2, int(1010 * yscale), subtitle, sub_font, TEXT_PRIMARY)

    d.rounded_rectangle([int(298 * scale), int(1082 * yscale), int(782 * scale), int(1138 * yscale)],
                        radius=int(28 * scale), fill=(*SURFACE_ELEVATED, 255), outline=(*TEAL, 92), width=max(1, int(1 * scale)))
    _center_text(d, w // 2, int(1110 * yscale), "광고 제거 · 계좌 공유 · 나머지 정산", _font(FONT_SDGOTHIC, int(26 * scale), index=7), TEAL)

    mock_w = int(880 * scale)
    mock_y = int(1165 * yscale)
    _draw_mock_calculator(d, scale, (w - mock_w) // 2, mock_y, mock_w)

    d.rounded_rectangle([int(72 * scale), h - int(108 * scale), w - int(72 * scale), h - int(52 * scale)],
                        radius=int(28 * scale), fill=(255, 255, 255, 10), outline=(255, 255, 255, 18), width=1)
    _center_text(d, w // 2, h - int(80 * scale), "프리미엄 다크 톤으로 더 선명하게", _font(FONT_SDGOTHIC, int(25 * scale), index=7), TEXT_SECONDARY)

    img.convert("RGB").save(OUT / (out_name or f"screenshot_{idx}.png"), "PNG", optimize=True)


def main():
    icon_512()
    feature_graphic()
    shots = [
        (1, "심플한 더치페이", "금액 + 인원수만 입력"),
        (2, "빠른 정산", "한 번에 N분의 1"),
    ]
    for idx, title, subtitle in shots:
        promo_screenshot(idx, title, subtitle, size=(1080, 1920), out_name=f"screenshot_{idx}.png")
        promo_screenshot(idx, title, subtitle, size=(1320, 2868), out_name=f"app_store_6_9_screenshot_{idx}.png")
    print("Generated:", sorted([p.name for p in OUT.iterdir() if p.suffix.lower() == ".png"]))


if __name__ == "__main__":
    main()
