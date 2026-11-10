#!/usr/bin/env python3
"""Cut Tato's sprite frames out of the approved concept boards.

The boards in assets/reference/ are illustrated sheets, not sprite atlases.
This tool isolates each pose (flood-fills the cream panel + ground shadow away,
drops loose speed lines / sparkles, un-mixes the edge pixels) and writes every
pose onto a same-sized transparent canvas with a shared foot anchor, so the
frames can be played back as animation without jitter.

Usage:  python3 tools/art/extract_tato.py            (writes game/assets/sprites/tato/)
        python3 tools/art/extract_tato.py --sheet    (also writes a review contact sheet)

No third-party packages needed.
"""
import os
import sys
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pngio import read_png, write_png  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
REF = os.path.join(ROOT, "assets", "reference")
OUT = os.path.join(ROOT, "game", "assets", "sprites", "tato")

CANVAS = 192          # every frame is CANVAS x CANVAS
ANCHOR = (96, 168)    # foot/ground anchor inside the canvas

# name: (sheet, x0, y0, x1, y1, options)
# Boxes are the ink bounds of each pose on the 1536x1024 boards.
# options: anchor = "ground" (bottom of the pose sits on ANCHOR.y)
#                 | "center" (pose centre sits 52 px above the anchor: airborne poses)
#          dy     = manual nudge in px after anchoring (positive = lower)
#          keep   = how many of the largest connected pieces to keep (default 1)
M = "movement_anatomy_sheet.png"
FRAMES = {
    # --- walk cycle (5 drawn keys) ---
    "walk_0": (M, 49, 414, 152, 534, {}),
    "walk_1": (M, 192, 413, 294, 534, {}),
    "walk_2": (M, 340, 412, 442, 531, {}),
    "walk_3": (M, 480, 413, 582, 534, {}),
    "walk_4": (M, 628, 410, 728, 530, {}),
    # --- run cycle (5 drawn keys) ---
    "run_0": (M, 812, 422, 917, 529, {}),
    "run_1": (M, 948, 423, 1055, 530, {}),
    "run_2": (M, 1091, 418, 1205, 524, {}),
    "run_3": (M, 1242, 414, 1348, 530, {}),
    "run_4": (M, 1381, 414, 1495, 528, {}),
    # --- jump / flutter ---
    "jump_crouch": (M, 46, 667, 142, 756, {}),
    "jump_takeoff": (M, 188, 637, 278, 749, {"anchor": "center"}),
    "jump_air": (M, 329, 610, 442, 721, {"anchor": "center"}),
    "jump_flap": (M, 479, 624, 593, 732, {"anchor": "center"}),
    "jump_land": (M, 625, 657, 724, 755, {}),
    # --- roll ---
    "roll_0": (M, 832, 641, 945, 753, {"anchor": "ball"}),
    "roll_1": (M, 998, 645, 1110, 751, {"anchor": "ball"}),
    "roll_2": (M, 1171, 644, 1280, 754, {"anchor": "ball"}),
    "roll_3": (M, 1355, 649, 1461, 755, {"anchor": "ball"}),
    # --- size variations ---
    "size_tiny": (M, 42, 905, 90, 960, {}),
    "size_base": (M, 114, 875, 189, 961, {}),
    "size_puffed": (M, 208, 872, 294, 961, {}),
    "size_giant": (M, 315, 834, 429, 963, {}),
    "size_ball": (M, 438, 882, 513, 956, {"anchor": "ball"}),
    # --- details ---
    "back_view": (M, 838, 842, 955, 964, {}),
    "cheer": (M, 1142, 845, 1259, 982, {}),
    # --- expressions (portrait busts) ---
    "face_happy": (M, 810, 60, 920, 166, {"anchor": "ball", "mb": 3, "robust": True}),
    "face_excited": (M, 951, 51, 1063, 164, {"anchor": "ball", "mb": 3}),
    "face_starstruck": (M, 1089, 53, 1204, 159, {"anchor": "ball", "mb": 3}),
    "face_munching": (M, 1228, 51, 1343, 163, {"anchor": "ball", "mb": 3}),
    "face_satisfied": (M, 1370, 52, 1488, 163, {"anchor": "ball", "mb": 3}),
    "face_surprised": (M, 814, 206, 925, 316, {"anchor": "ball", "mb": 3}),
    "face_determined": (M, 948, 209, 1061, 310, {"anchor": "ball", "mb": 3}),
    "face_focused": (M, 1089, 210, 1203, 312, {"anchor": "ball", "mb": 3}),
    "face_worried": (M, 1232, 208, 1348, 313, {"anchor": "ball", "mb": 3}),
    "face_sleepy": (M, 1373, 216, 1483, 315, {"anchor": "ball", "mb": 3}),
}

MARGIN = 9
_sheets = {}


def sheet(name):
    if name not in _sheets:
        _sheets[name] = read_png(os.path.join(REF, name))
    return _sheets[name]


def border_bg(px, w, h):
    """Most common (quantised) colour along the top/side borders of a crop."""
    counts = {}
    def add(x, y):
        i = (y * w + x) * 4
        key = (px[i] >> 2, px[i + 1] >> 2, px[i + 2] >> 2)
        counts[key] = counts.get(key, 0) + 1
    for x in range(w):
        add(x, 0)
        add(x, 1)
    for y in range(h * 2 // 3):
        add(0, y)
        add(w - 1, y)
    key = max(counts, key=counts.get)
    return (key[0] * 4 + 2, key[1] * 4 + 2, key[2] * 4 + 2)


def is_shadow(r, g, b):
    """Soft lavender ground shadow painted under the poses on the boards."""
    luma = (r * 3 + g * 6 + b) // 10
    sat = max(r, g, b) - min(r, g, b)
    return 178 <= luma <= 244 and b >= r - 10 and sat <= 46 and g <= b + 4


def cut(name, spec):
    sname, x0, y0, x1, y1, opt = spec
    sw, sh, spx = sheet(sname)
    cx0 = max(0, x0 - MARGIN)
    cy0 = max(0, y0 - MARGIN)
    cx1 = min(sw - 1, x1 + MARGIN)
    cy1 = min(sh - 1, y1 + opt.get("mb", MARGIN + 6))
    w = cx1 - cx0 + 1
    h = cy1 - cy0 + 1
    px = bytearray(w * h * 4)
    for y in range(h):
        s = ((cy0 + y) * sw + cx0) * 4
        px[y * w * 4:(y + 1) * w * 4] = spx[s:s + w * 4]
    bg = border_bg(px, w, h)
    bubble = opt.get("bubble", False)

    # 1 = can be flooded as background
    passable = bytearray(w * h)
    for i in range(w * h):
        r, g, b = px[i * 4], px[i * 4 + 1], px[i * 4 + 2]
        d = max(abs(r - bg[0]), abs(g - bg[1]), abs(b - bg[2]))
        if d <= 13:
            passable[i] = 1
        elif not bubble and is_shadow(r, g, b):
            passable[i] = 2
    # "robust" poses have a hairline gap in their outline: only let the flood
    # travel through pixels whose whole 3x3 neighbourhood is background-like,
    # then grow the result back by two pixels.
    robust = opt.get("robust", False)
    travel = passable
    if robust:
        travel = bytearray(w * h)
        for y in range(1, h - 1):
            for x in range(1, w - 1):
                i = y * w + x
                if passable[i] and all(passable[i + o] for o in (-1, 1, -w, w, -w - 1, -w + 1, w - 1, w + 1)):
                    travel[i] = 1
        for x in range(w):
            travel[x] = passable[x]
            travel[(h - 1) * w + x] = passable[(h - 1) * w + x]
        for y in range(h):
            travel[y * w] = passable[y * w]
            travel[y * w + w - 1] = passable[y * w + w - 1]
    passable_all = passable
    passable = travel
    # flood from the crop border, 4-connected
    isbg = bytearray(w * h)
    q = deque()
    for x in range(w):
        for y in (0, h - 1):
            i = y * w + x
            if passable[i] and not isbg[i]:
                isbg[i] = 1
                q.append(i)
    for y in range(h):
        for x in (0, w - 1):
            i = y * w + x
            if passable[i] and not isbg[i]:
                isbg[i] = 1
                q.append(i)
    while q:
        p = q.popleft()
        x = p % w
        y = p // w
        if x > 0 and passable[p - 1] and not isbg[p - 1]:
            isbg[p - 1] = 1
            q.append(p - 1)
        if x < w - 1 and passable[p + 1] and not isbg[p + 1]:
            isbg[p + 1] = 1
            q.append(p + 1)
        if y > 0 and passable[p - w] and not isbg[p - w]:
            isbg[p - w] = 1
            q.append(p - w)
        if y < h - 1 and passable[p + w] and not isbg[p + w]:
            isbg[p + w] = 1
            q.append(p + w)

    if robust:
        for _ in range(2):
            grow = []
            for i in range(w * h):
                if not isbg[i] and passable_all[i]:
                    x = i % w
                    y = i // w
                    if (x > 0 and isbg[i - 1]) or (x < w - 1 and isbg[i + 1]) or (y > 0 and isbg[i - w]) or (y < h - 1 and isbg[i + w]):
                        grow.append(i)
            for i in grow:
                isbg[i] = 1

    # connected foreground pieces; keep the biggest (drops speed lines, sparkles, labels)
    comp = [0] * (w * h)
    sizes = [0]
    for s in range(w * h):
        if not isbg[s] and comp[s] == 0:
            cid = len(sizes)
            sizes.append(0)
            comp[s] = cid
            q.append(s)
            while q:
                p = q.popleft()
                sizes[cid] += 1
                x = p % w
                y = p // w
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
                    nx = x + dx
                    ny = y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        n = ny * w + nx
                        if not isbg[n] and comp[n] == 0:
                            comp[n] = cid
                            q.append(n)
    keep_n = opt.get("keep", 1)
    order = sorted(range(1, len(sizes)), key=lambda c: -sizes[c])[:keep_n]
    keep = set(order)

    out = bytearray(w * h * 4)
    minx, miny, maxx, maxy = w, h, -1, -1
    sumx = 0
    count = 0
    for i in range(w * h):
        if comp[i] in keep:
            x = i % w
            y = i // w
            r, g, b = px[i * 4], px[i * 4 + 1], px[i * 4 + 2]
            a = 255
            # edge pixel = touches background: un-mix the panel colour out of it
            edge = False
            for n in (i - 1, i + 1, i - w, i + w):
                if 0 <= n < w * h and (isbg[n] or comp[n] not in keep):
                    edge = True
                    break
            if edge:
                d = max(abs(r - bg[0]), abs(g - bg[1]), abs(b - bg[2]))
                af = min(1.0, max(0.18, d / 78.0))
                r = int(min(255, max(0, (r - (1 - af) * bg[0]) / af)))
                g = int(min(255, max(0, (g - (1 - af) * bg[1]) / af)))
                b = int(min(255, max(0, (b - (1 - af) * bg[2]) / af)))
                a = int(af * 255)
            out[i * 4] = r
            out[i * 4 + 1] = g
            out[i * 4 + 2] = b
            out[i * 4 + 3] = a
            if a > 60:
                minx = min(minx, x)
                maxx = max(maxx, x)
                miny = min(miny, y)
                maxy = max(maxy, y)
                sumx += x
                count += 1
    cxm = sumx / max(1, count)
    return {
        "w": w, "h": h, "px": out, "bbox": (minx, miny, maxx, maxy), "cx": cxm,
        "opt": opt, "pieces": sorted(sizes[1:], reverse=True)[:5],
    }


def place(cutout):
    """Paste a cut pose into the shared canvas at the foot anchor."""
    w, h, px = cutout["w"], cutout["h"], cutout["px"]
    minx, miny, maxx, maxy = cutout["bbox"]
    opt = cutout["opt"]
    mode = opt.get("anchor", "ground")
    if mode == "ground":
        ox = ANCHOR[0] - int(round(cutout["cx"]))
        oy = ANCHOR[1] - maxy
    elif mode == "center":
        ox = ANCHOR[0] - int(round(cutout["cx"]))
        oy = (ANCHOR[1] - 56) - (miny + maxy) // 2
    else:  # ball: centre the bbox, sit on the ground line
        ox = ANCHOR[0] - (minx + maxx) // 2
        oy = ANCHOR[1] - maxy
    ox += opt.get("dx", 0)
    oy += opt.get("dy", 0)
    canvas = bytearray(CANVAS * CANVAS * 4)
    for y in range(h):
        ty = y + oy
        if ty < 0 or ty >= CANVAS:
            continue
        for x in range(w):
            a = px[(y * w + x) * 4 + 3]
            if a == 0:
                continue
            tx = x + ox
            if 0 <= tx < CANVAS:
                s = (y * w + x) * 4
                t = (ty * CANVAS + tx) * 4
                canvas[t:t + 4] = px[s:s + 4]
    return canvas


def contact_sheet(frames, path, cols=8, bgc=(120, 170, 120)):
    names = list(frames.keys())
    rows = (len(names) + cols - 1) // cols
    W = cols * CANVAS
    H = rows * CANVAS
    img = bytearray(W * H * 4)
    for i in range(W * H):
        cx = (i % W) // 24
        cy = (i // W) // 24
        shade = 0 if (cx + cy) % 2 == 0 else 14
        img[i * 4] = bgc[0] + shade
        img[i * 4 + 1] = bgc[1] + shade
        img[i * 4 + 2] = bgc[2] + shade
        img[i * 4 + 3] = 255
    for idx, n in enumerate(names):
        fx = (idx % cols) * CANVAS
        fy = (idx // cols) * CANVAS
        fr = frames[n]
        for y in range(CANVAS):
            for x in range(CANVAS):
                s = (y * CANVAS + x) * 4
                a = fr[s + 3]
                if a:
                    t = ((fy + y) * W + fx + x) * 4
                    for c in range(3):
                        img[t + c] = (fr[s + c] * a + img[t + c] * (255 - a)) // 255
        # ground line
        gy = fy + ANCHOR[1]
        for x in range(fx + 20, fx + CANVAS - 20, 3):
            t = (gy * W + x) * 4
            img[t:t + 3] = bytes((60, 40, 90))
    write_png(path, W, H, img)


def main():
    os.makedirs(OUT, exist_ok=True)
    only = [a for a in sys.argv[1:] if not a.startswith("--")]
    frames = {}
    for name, spec in FRAMES.items():
        if only and not any(name.startswith(o) for o in only):
            continue
        c = cut(name, spec)
        frames[name] = place(c)
        write_png(os.path.join(OUT, name + ".png"), CANVAS, CANVAS, frames[name])
        print("%-16s bbox=%s pieces=%s" % (name, c["bbox"], c["pieces"]))
    if "--sheet" in sys.argv:
        sheet_path = os.path.join(ROOT, "docs", "art", "tato_contact_sheet.png")
        os.makedirs(os.path.dirname(sheet_path), exist_ok=True)
        contact_sheet(frames, sheet_path)
        print("contact sheet:", sheet_path)


if __name__ == "__main__":
    main()
