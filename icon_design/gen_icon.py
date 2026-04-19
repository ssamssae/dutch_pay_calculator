"""
Generate dutch pay app icon.
Design: amber background, 3 person-circles on top, horizontal bar (division line),
        large ₩ symbol on bottom.
Outputs:
  - icon_1024.png         (RGB, no alpha — iOS 1024x1024 master)
  - icon_fg_1024.png      (RGBA transparent background, Android adaptive foreground)
  - icon_bg_1024.png      (solid amber, Android adaptive background)
"""
from PIL import Image, ImageDraw, ImageFont
from pathlib import Path

SIZE = 1024
AMBER = (255, 179, 0, 255)
WHITE = (255, 255, 255, 255)

OUT = Path(__file__).parent


def draw_foreground(img: Image.Image, safe_pad: int = 0):
    """Draw 3 person-circles + big ₩. safe_pad shrinks content for Android adaptive."""
    d = ImageDraw.Draw(img)
    w, h = img.size
    cx = w // 2
    cy = h // 2

    scale = 1.0 - safe_pad / 1024 * 2
    def sx(x): return int(cx + (x - 512) * scale)
    def sy(y): return int(cy + (y - 512) * scale)
    def sr(r): return int(r * scale)

    # 3 person heads — top, well-spaced (not touching)
    head_r = 80
    for x in (332, 512, 692):
        r = sr(head_r)
        d.ellipse([sx(x) - r, sy(300) - r, sx(x) + r, sy(300) + r], fill=WHITE)

    # Big ₩ — hand-drawn. Stroke width matches circle feel.
    stroke = sr(82)
    # W span: x 240..784 (544 wide), y 520..960 (440 tall). Peak at y 720.
    ax, ay = sx(240), sy(520)
    bx, by = sx(376), sy(960)
    px, py = sx(512), sy(720)
    qx, qy = sx(648), sy(960)
    rx, ry = sx(784), sy(520)

    def rline(p1, p2, wpx):
        d.line([p1, p2], fill=WHITE, width=wpx)
        for (x, y) in (p1, p2):
            d.ellipse([x - wpx // 2, y - wpx // 2, x + wpx // 2, y + wpx // 2], fill=WHITE)

    rline((ax, ay), (bx, by), stroke)
    rline((bx, by), (px, py), stroke)
    rline((px, py), (qx, qy), stroke)
    rline((qx, qy), (rx, ry), stroke)

    # Two horizontal bars (double-bar ₩) — positioned in upper third of W,
    # clearly separated from the center peak.
    bar_w = sr(56)
    bar_x0, bar_x1 = sx(180), sx(844)
    for by_pos in (sy(580), sy(650)):
        d.rounded_rectangle(
            [bar_x0, by_pos - bar_w // 2, bar_x1, by_pos + bar_w // 2],
            radius=bar_w // 2, fill=WHITE,
        )


def main():
    # 1) Master 1024 (RGB, no alpha) for iOS & master
    master = Image.new("RGB", (SIZE, SIZE), AMBER[:3])
    # draw onto RGBA then composite
    layer = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_foreground(layer)
    master.paste(Image.alpha_composite(Image.new("RGBA", (SIZE, SIZE), AMBER), layer).convert("RGB"))
    master.save(OUT / "icon_1024.png", "PNG")

    # 2) Android adaptive foreground (transparent bg, content fits in safe ~66%)
    fg = Image.new("RGBA", (SIZE, SIZE), (0, 0, 0, 0))
    draw_foreground(fg, safe_pad=170)  # shrink to inner ~66%
    fg.save(OUT / "icon_fg_1024.png", "PNG")

    # 3) Android adaptive background (solid amber)
    bg = Image.new("RGB", (SIZE, SIZE), AMBER[:3])
    bg.save(OUT / "icon_bg_1024.png", "PNG")

    print("generated:", sorted(p.name for p in OUT.glob("icon_*.png")))


if __name__ == "__main__":
    main()
