"""
Generate Play Store assets for 더치페이 계산기:
- icon_512.png (512x512)
- feature_graphic.png (1024x500)
- placeholder_screenshot_*.png (1080x1920, 2 shots)
"""
from PIL import Image, ImageDraw, ImageFont, ImageFilter
from pathlib import Path

OUT = Path("/Users/user/dutch_pay_calculator/icon_design/store_assets")
OUT.mkdir(parents=True, exist_ok=True)

MASTER = Path("/Users/user/dutch_pay_calculator/icon_design/icon_final_1024.png")
AMBER = (255, 179, 0)
AMBER_DEEP = (230, 145, 0)
DARK = (17, 24, 39)
WHITE = (255, 255, 255)

FONT_SDGOTHIC = "/System/Library/Fonts/AppleSDGothicNeo.ttc"
FONT_PRETENDARD_BLACK = "/Users/user/Library/Fonts/Pretendard-Black.otf"


def _center_text(d, cx, cy, text, font, fill):
    bbox = d.textbbox((0, 0), text, font=font, anchor="lt")
    w = bbox[2] - bbox[0]
    h = bbox[3] - bbox[1]
    d.text((cx - w // 2 - bbox[0], cy - h // 2 - bbox[1]),
           text, font=font, fill=fill)


def icon_512():
    im = Image.open(MASTER)
    im.resize((512, 512), Image.LANCZOS).save(OUT / "icon_512.png", "PNG", optimize=True)


def feature_graphic():
    # 1024 x 500, amber gradient + white app name + small icon
    img = Image.new("RGB", (1024, 500), AMBER)
    # overlay subtle gradient
    overlay = Image.new("RGBA", (1024, 500), (0, 0, 0, 0))
    od = ImageDraw.Draw(overlay)
    for i in range(500):
        a = int(50 * (i / 500))
        od.line([(0, i), (1024, i)], fill=(200, 120, 0, a))
    img = Image.alpha_composite(img.convert("RGBA"), overlay).convert("RGB")
    d = ImageDraw.Draw(img, "RGBA")

    # icon on left
    icon = Image.open(MASTER).resize((280, 280), Image.LANCZOS)
    img.paste(icon, (90, 110), icon if icon.mode == "RGBA" else None)

    # title + subtitle on right
    title_font = ImageFont.truetype(FONT_PRETENDARD_BLACK, 96)
    sub_font = ImageFont.truetype(FONT_SDGOTHIC, 40, index=7)
    d.text((430, 150), "더치페이 계산기", font=title_font, fill=WHITE)
    d.text((430, 280), "여럿이 먹은 자리, 깔끔하게 N분의 1", font=sub_font, fill=(255, 255, 255, 230))
    img.save(OUT / "feature_graphic.png", "PNG", optimize=True)


def placeholder_screenshot(idx, title, subtitle):
    # 1080 x 1920 portrait mockup
    img = Image.new("RGB", (1080, 1920), DARK)
    d = ImageDraw.Draw(img, "RGBA")

    # top band with amber
    d.rectangle([0, 0, 1080, 260], fill=AMBER)

    # App title
    title_font = ImageFont.truetype(FONT_PRETENDARD_BLACK, 72)
    _center_text(d, 540, 140, "더치페이 계산기", title_font, DARK)

    # Big icon in middle
    icon = Image.open(MASTER).resize((360, 360), Image.LANCZOS)
    img.paste(icon, (360, 440), icon if icon.mode == "RGBA" else None)

    # Feature title
    feat_font = ImageFont.truetype(FONT_PRETENDARD_BLACK, 80)
    _center_text(d, 540, 950, title, feat_font, AMBER)

    # Subtitle
    sub_font = ImageFont.truetype(FONT_SDGOTHIC, 48, index=7)
    _center_text(d, 540, 1060, subtitle, sub_font, WHITE)

    # Mock calculator UI at bottom
    d.rounded_rectangle([100, 1180, 980, 1780], radius=40, fill=(30, 40, 60))
    fld_font = ImageFont.truetype(FONT_SDGOTHIC, 44, index=7)
    d.text((160, 1230), "총 금액", font=fld_font, fill=(200, 200, 200))
    d.rounded_rectangle([160, 1290, 920, 1380], radius=16, fill=(50, 60, 80))
    _center_text(d, 540, 1335, "120,000 원", feat_font.font_variant(size=56), WHITE)
    d.text((160, 1420), "인원수", font=fld_font, fill=(200, 200, 200))
    d.rounded_rectangle([160, 1480, 920, 1570], radius=16, fill=(50, 60, 80))
    _center_text(d, 540, 1525, "5 명", feat_font.font_variant(size=56), WHITE)
    d.rounded_rectangle([160, 1620, 920, 1740], radius=20, fill=AMBER)
    _center_text(d, 540, 1680, "1인당 24,000원", feat_font.font_variant(size=52), DARK)

    img.save(OUT / f"screenshot_{idx}.png", "PNG", optimize=True)


def main():
    icon_512()
    feature_graphic()
    placeholder_screenshot(1, "심플한 더치페이", "금액 + 인원수만 입력")
    placeholder_screenshot(2, "빠른 정산", "한 번에 N분의 1")
    print("Generated:", sorted([p.name for p in OUT.iterdir()]))


if __name__ == "__main__":
    main()
