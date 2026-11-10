#!/usr/bin/env python3
"""Generates the game's vector art (SVG) from code. Run after changing any art_*.py:

    python3 tools/art/make_art.py

Tato's own frames are NOT made here: they are cut from the approved concept
boards by tools/art/extract_tato.py.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
ROOT = os.path.dirname(os.path.dirname(HERE))
ASSETS = os.path.join(ROOT, "game", "assets")


def main():
    made = []
    import art_tiles
    made += art_tiles.make_all(os.path.join(ASSETS, "tiles"))
    for name in ("art_props", "art_foods", "art_creatures", "art_backgrounds", "art_ui", "art_bosses"):
        try:
            mod = __import__(name)
        except ModuleNotFoundError:
            continue
        made += mod.make_all(ASSETS)
    print("generated %d files" % len(made))


if __name__ == "__main__":
    main()
