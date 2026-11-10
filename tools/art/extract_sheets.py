#!/usr/bin/env python3
"""Cuts the game's pictures out of the five approved TATO! boards
(assets/reference/*_sheet.png) into game/assets/sprites/.

    python3 tools/art/extract_sheets.py            cut everything
    python3 tools/art/extract_sheets.py enemies    only groups whose name starts with this
    add --review to also write contact sheets into docs/art/

Every entry below is: output names, board, rectangle, how to find the art.
Nothing is redrawn: these are the approved illustrations themselves.
"""
import os
import sys

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from cutter import cut_panel, cut_all, trim_thin, crop, save, contact_sheet, ROOT  # noqa: E402
from pngio import write_png  # noqa: E402

OUT = os.path.join(ROOT, "game", "assets", "sprites")
E = "enemies_bosses_sheet.png"
I = "items_powerups_sheet.png"
D = "direction_sheet.png"
G = "gameplay_redesign_sheet.png"
W = "world_assets_sheet.png"

# group, [names], sheet, rect, options
CUTS = [
    # ---- creatures (Enemy & Boss Concept Bible) ----
    ("enemies", ["mushroom_hopper", "slime_blob", "apple_chomper", "bee_buzzer", "hedgehog_roller", "turtle_tank"], E, (216, 108, 1442, 197), {}),
    ("enemies", ["crow_swooper", "ghost_poof", "crab_snipper", "mole_digger", "onion_knight", "carrot_archer"], E, (216, 278, 1442, 355), {}),
    ("enemies", ["pie_bat", "ice_puffin", "candy_imp", "pepper_goblin", "rock_golem", "balloon_jelly"], E, (216, 424, 1442, 506), {"merge": 4}),
    ("enemies", ["fire_slime", "ice_slime", "shock_slime"], E, (1132, 618, 1428, 684), {"merge": 6}),
    # ---- core items, interactives, bowls, pickups (Item & Power-Up sheet) ----
    ("items", ["coin"], I, (24, 256, 108, 334), {}),
    ("items", ["star"], I, (116, 256, 202, 334), {}),
    ("items", ["heart"], I, (210, 256, 296, 334), {}),
    ("items", ["checkpoint"], I, (298, 244, 394, 336), {"merge": 6}),
    ("items", ["key"], I, (394, 248, 482, 336), {}),
    ("items", ["treasure_note"], I, (482, 246, 578, 336), {}),
    ("items", ["spring_pad"], I, (612, 256, 706, 338), {"merge": 4}),
    ("items", ["crate"], I, (704, 250, 844, 338), {"merge": 12}),
    ("items", ["question_block"], I, (846, 248, 942, 338), {}),
    ("items", ["move_button"], I, (948, 242, 1084, 338), {"merge": 10}),
    ("items", ["bowl_noodle", "bowl_fruit", "bowl_corn"], I, (1108, 252, 1440, 346), {}),
    ("pickups", ["gem", "orb", "flower", "clover", "feather", "leaf", "candy", "crystal", "rainbow_star", "moon",
                 "sun", "cherry", "grape", "banana", "corn", "mushroom", "egg", "time", "magnet", "wings"], I, (18, 424, 1432, 486), {"merge": 3}),
    # ---- the big Tato drawings ----
    ("tato_big", ["front"], D, (55, 112, 335, 372), {"merge": 0}),
    ("tato_big", ["side"], D, (345, 140, 585, 372), {"merge": 0}),
    ("tato_big", ["cheer"], E, (14, 118, 210, 322), {"merge": 0}),
    ("tato_big", ["defeat"], G, (262, 872, 392, 978), {"merge": 8}),
    ("tato_big", ["respawn"], G, (404, 866, 522, 980), {"merge": 0}),
    ("items", ["extra_heal"], G, (846, 858, 1004, 946), {"merge": 6}),
    ("ui", ["btn_move"], G, (1034, 884, 1184, 970), {}),
    ("ui", ["btn_jump"], G, (1188, 884, 1288, 970), {}),
    ("ui", ["btn_attack"], G, (1292, 862, 1430, 972), {"merge": 0}),
]

# Power-up icons sit on soft colour gradients: flood by small colour steps.
POWER_IDS = [
    ["fire_pepper", "frostberry", "bubbleberry"],
    ["honeycomb", "watermelon", "popcorn"],
    ["noodle", "thunder_corn", "tomato_bomb"],
    ["garlic_dash", "lemon_beam", "cocoa_shield"],
]
PANEL_X = [14, 492, 968]
PANEL_Y = [604, 712, 816, 918]
PANEL_W = 466
PANEL_H = 96

# Plain rectangles kept as illustrations (world cards, action demos, mock screens).
RECTS = [
    ("cards", "world_grassland", D, (18, 880, 265, 986)),
    ("cards", "world_orchard", D, (273, 880, 513, 986)),
    ("cards", "world_candy", D, (520, 880, 741, 986)),
    ("cards", "world_icy", D, (748, 880, 968, 986)),
    ("cards", "world_windy", D, (975, 880, 1195, 986)),
    ("cards", "world_castle", D, (1202, 880, 1428, 986)),
    ("cards", "mock_direction", D, (600, 108, 1430, 510)),
    ("cards", "mock_grassland", G, (12, 110, 714, 374)),
    ("cards", "mock_icy", G, (737, 110, 1436, 374)),
    ("cards", "mock_candy", G, (12, 426, 714, 684)),
    ("cards", "mock_castle", G, (737, 426, 1436, 684)),
    ("cards", "scene_grassland", W, (12, 112, 350, 366)),
    ("cards", "scene_orchard", W, (735, 112, 1073, 366)),
    ("cards", "scene_candy", W, (12, 424, 350, 664)),
    ("cards", "scene_icy", W, (735, 424, 1073, 664)),
    ("cards", "scene_windy", W, (12, 718, 350, 972)),
    ("cards", "scene_castle", W, (735, 718, 1073, 972)),
]

# The six world kits on the level-asset board share one layout.
WORLD_ORIGINS = {
    "grassland": (0, 0), "orchard": (723, 0),
    "candy": (0, 310), "icy": (723, 310),
    "windy": (0, 607), "castle": (723, 607),
}
# The asset blocks are three rows: a = tiles, b = hazards + props,
# c = checkpoint, signpost, power bowl, collectibles. Every drawing in a row
# is cut, left to right, and saved as <world>_<row><index>.png.
WORLD_ROWS = [
    ("a", (358, 104, 558, 164)),
    ("b", (358, 172, 716, 228)),
    ("c", (358, 232, 716, 300)),
]


def save_rect(sheet_name, rect, path):
    w, h, px = crop(sheet_name, rect)
    os.makedirs(os.path.dirname(path), exist_ok=True)
    write_png(path, w, h, px)
    return {"w": w, "h": h, "px": px}


def main():
    only = [a for a in sys.argv[1:] if not a.startswith("--")]
    review = "--review" in sys.argv
    groups = {}

    def want(g):
        return not only or any(g.startswith(o) for o in only)

    for group, names, sheet_name, rect, opt in CUTS:
        if not want(group):
            continue
        cuts = cut_panel(sheet_name, rect, len(names), opt.get("mode", "flat"), merge=opt.get("merge", 0), order=opt.get("order", "x"))
        if len(cuts) != len(names):
            print("!! %s: expected %d drawings, found %d" % (names, len(names), len(cuts)))
        for name, cut in zip(names, cuts):
            save(cut, os.path.join(OUT, group, name + ".png"))
            groups.setdefault(group, []).append(cut)
            print("%-9s %-18s %3dx%-3d" % (group, name, cut["w"], cut["h"]))

    if want("powers"):
        for r, row in enumerate(POWER_IDS):
            for c, pid in enumerate(row):
                x = PANEL_X[c]
                y = PANEL_Y[r]
                # the icon is in the left end of its panel
                cuts = cut_panel(I, (x + 2, y - 6, x + 96, y + 90), 1, "grad", merge=0, step=10, min_luma=120, pills=True)
                if pid == "garlic_dash":
                    # pale garlic on a pale panel: take smaller colour steps
                    cuts = cut_panel(I, (x + 2, y - 10, x + 90, y + 74), 1, "grad", merge=0, step=4, min_luma=150, pills=True)
                if cuts:
                    cuts[0] = trim_thin(cuts[0], 6)
                    save(cuts[0], os.path.join(OUT, "powers", pid + ".png"))
                    groups.setdefault("powers", []).append(cuts[0])
                    print("powers    %-18s %3dx%-3d" % (pid, cuts[0]["w"], cuts[0]["h"]))
                demo = save_rect(I, (x + 4, y + 2, x + PANEL_W - 4, y + PANEL_H - 2), os.path.join(OUT, "cards", "demo_" + pid + ".png"))
                groups.setdefault("demos", []).append(demo)

    if want("bosses"):
        boss_rects = [
            ("mega_mushroot", (10, 812, 250, 958)), ("gigantapple", (258, 812, 488, 956)),
            ("candy_king", (494, 812, 722, 958)), ("frost_puffin_lord", (732, 812, 958, 958)),
            ("sky_airship_turtle", (966, 812, 1196, 958)), ("chef_castle_golem", (1204, 812, 1438, 958)),
        ]
        for name, rect in boss_rects:
            # painted backdrops: flood by small colour steps, keep the biggest drawing
            cuts = cut_panel(E, rect, 1, "grad", merge=0, step=16, min_luma=60)
            if cuts:
                cut = trim_thin(cuts[0], 14)
                save(cut, os.path.join(OUT, "bosses", name + ".png"))
                groups.setdefault("bosses", []).append(cut)
                print("bosses    %-18s %3dx%-3d" % (name, cut["w"], cut["h"]))

    if want("cards"):
        for group, name, sheet_name, rect in RECTS:
            save_rect(sheet_name, rect, os.path.join(OUT, group, name + ".png"))
            print("cards     %-18s" % name)

    if want("world"):
        for world, (ox, oy) in WORLD_ORIGINS.items():
            for row, rect in WORLD_ROWS:
                r = (rect[0] + ox, rect[1] + oy, rect[2] + ox, rect[3] + oy)
                cuts = cut_all(W, r, "flat", min_size=90, gap=4, thr=20, shadows=False)
                for i, cut in enumerate(cuts):
                    cut = trim_thin(cut, 4)
                    save(cut, os.path.join(OUT, "world", "%s_%s%d.png" % (world, row, i)))
                    groups.setdefault("world", []).append(cut)
                print("world     %-10s row %s: %d drawings" % (world, row, len(cuts)))
                # keep each world's rows aligned on the review sheet
                while len(groups["world"]) % 12 != 0:
                    groups["world"].append(None)

    if review:
        for g, cuts in groups.items():
            cell = 150 if g not in ("tato_big", "demos", "bosses") else 300
            if g == "world":
                cell = 84
            if g == "demos":
                continue
            contact_sheet(cuts, os.path.join(ROOT, "docs", "art", "cut_%s.png" % g), cell=cell, cols=12 if g == "world" else (8 if cell == 150 else 4))
            print("review sheet: docs/art/cut_%s.png" % g)


if __name__ == "__main__":
    main()
