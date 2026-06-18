#!/usr/bin/env python3
"""Regression checks for store promo asset generation."""
import importlib.util
import tempfile
from pathlib import Path

from PIL import Image


ROOT = Path(__file__).resolve().parents[1]
MODULE_PATH = ROOT / "icon_design" / "gen_store_assets.py"


def load_module():
    spec = importlib.util.spec_from_file_location("gen_store_assets", MODULE_PATH)
    module = importlib.util.module_from_spec(spec)
    spec.loader.exec_module(module)
    return module


def main():
    mod = load_module()

    assert mod.OUT == ROOT / "icon_design" / "store_assets"
    assert mod.MASTER == ROOT / "icon_design" / "icon3_master.png"
    assert mod.TEAL == (61, 224, 200)
    assert mod.BG_DEEP == (10, 20, 34)
    assert mod.SURFACE == (19, 32, 58)

    with tempfile.TemporaryDirectory() as tmp:
        mod.OUT = Path(tmp)
        mod.main()

        expected_sizes = {
            "icon_512.png": (512, 512),
            "feature_graphic.png": (1024, 500),
            "screenshot_1.png": (1080, 1920),
            "screenshot_2.png": (1080, 1920),
            "app_store_6_9_screenshot_1.png": (1320, 2868),
            "app_store_6_9_screenshot_2.png": (1320, 2868),
        }
        for name, size in expected_sizes.items():
            path = mod.OUT / name
            assert path.exists(), name
            with Image.open(path) as im:
                assert im.size == size, (name, im.size)

        with Image.open(mod.OUT / "screenshot_1.png") as im:
            # Header and CTA should be teal-family, not the legacy amber band.
            header_pixel = im.convert("RGB").getpixel((540, 80))
            cta_pixel = im.convert("RGB").getpixel((200, 1705))
            assert header_pixel[1] > 120 and header_pixel[2] > 120, header_pixel
            assert cta_pixel[1] > 120 and cta_pixel[2] > 120, cta_pixel
            assert header_pixel[0] < 120 and cta_pixel[0] < 120

    print("OK")


if __name__ == "__main__":
    main()
