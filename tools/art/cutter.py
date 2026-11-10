"""Cuts individual pictures out of the illustrated concept boards.

The boards are flat images. A "panel" is a rectangle on a board that holds
one or more drawings on a plain (or softly shaded) backdrop. cut_panel()
floods the backdrop away from the rectangle's edge, keeps the N biggest
drawings, un-mixes the backdrop colour out of their edge pixels, and returns
them trimmed, sorted in reading order.
"""
import os
import sys
from collections import deque

HERE = os.path.dirname(os.path.abspath(__file__))
sys.path.insert(0, HERE)
from pngio import read_png, write_png  # noqa: E402

ROOT = os.path.dirname(os.path.dirname(HERE))
REF = os.path.join(ROOT, "assets", "reference")

_sheets = {}


def sheet(name):
    if name not in _sheets:
        _sheets[name] = read_png(os.path.join(REF, name))
    return _sheets[name]


def is_shadow(r, g, b):
    luma = (r * 3 + g * 6 + b) // 10
    sat = max(r, g, b) - min(r, g, b)
    return 178 <= luma <= 244 and b >= r - 10 and sat <= 46 and g <= b + 4


def crop(sheet_name, rect):
    sw, sh, spx = sheet(sheet_name)
    x0, y0, x1, y1 = rect
    x0 = max(0, x0)
    y0 = max(0, y0)
    x1 = min(sw - 1, x1)
    y1 = min(sh - 1, y1)
    w = x1 - x0 + 1
    h = y1 - y0 + 1
    px = bytearray(w * h * 4)
    for y in range(h):
        s = ((y0 + y) * sw + x0) * 4
        px[y * w * 4:(y + 1) * w * 4] = spx[s:s + w * 4]
    return w, h, px


def _border_bg(px, w, h):
    counts = {}
    for x in range(w):
        for y in (0, h - 1):
            i = (y * w + x) * 4
            k = (px[i] >> 2, px[i + 1] >> 2, px[i + 2] >> 2)
            counts[k] = counts.get(k, 0) + 1
    for y in range(h):
        for x in (0, w - 1):
            i = (y * w + x) * 4
            k = (px[i] >> 2, px[i + 1] >> 2, px[i + 2] >> 2)
            counts[k] = counts.get(k, 0) + 1
    k = max(counts, key=counts.get)
    return (k[0] * 4 + 2, k[1] * 4 + 2, k[2] * 4 + 2)


def is_label_pill(r, g, b):
    """The plum name tags that sit behind some icons on the boards."""
    return 70 <= r <= 185 and g < 125 and 45 <= b <= 165 and r > g + 38 and b > g + 18


def background_mask(px, w, h, mode="flat", thr=14, step=9, min_luma=150, shadows=True, robust=False, seeds=None, pills=False):
    """1 where the pixel is backdrop. mode "flat": close to the border colour.
    mode "grad": reached from the border through small colour steps (soft
    gradients) without crossing anything dark."""
    n = w * h
    isbg = bytearray(n)
    q = deque()
    if mode == "flat":
        bg = _border_bg(px, w, h)
        passable = bytearray(n)
        for i in range(n):
            r, g, b = px[i * 4], px[i * 4 + 1], px[i * 4 + 2]
            if max(abs(r - bg[0]), abs(g - bg[1]), abs(b - bg[2])) <= thr:
                passable[i] = 1
            elif shadows and is_shadow(r, g, b):
                passable[i] = 1
        travel = passable
        if robust:
            travel = bytearray(n)
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
        starts = []
        for x in range(w):
            starts += [x, (h - 1) * w + x]
        for y in range(h):
            starts += [y * w, y * w + w - 1]
        for s in starts:
            if travel[s] and not isbg[s]:
                isbg[s] = 1
                q.append(s)
        while q:
            p = q.popleft()
            x = p % w
            y = p // w
            if x > 0 and travel[p - 1] and not isbg[p - 1]:
                isbg[p - 1] = 1
                q.append(p - 1)
            if x < w - 1 and travel[p + 1] and not isbg[p + 1]:
                isbg[p + 1] = 1
                q.append(p + 1)
            if y > 0 and travel[p - w] and not isbg[p - w]:
                isbg[p - w] = 1
                q.append(p - w)
            if y < h - 1 and travel[p + w] and not isbg[p + w]:
                isbg[p + w] = 1
                q.append(p + w)
        if robust:
            for _ in range(2):
                grow = []
                for i in range(n):
                    if not isbg[i] and passable[i]:
                        x = i % w
                        y = i // w
                        if (x > 0 and isbg[i - 1]) or (x < w - 1 and isbg[i + 1]) or (y > 0 and isbg[i - w]) or (y < h - 1 and isbg[i + w]):
                            grow.append(i)
                for i in grow:
                    isbg[i] = 1
        return isbg
    # gradient mode
    luma = bytearray(n)
    for i in range(n):
        luma[i] = (px[i * 4] * 3 + px[i * 4 + 1] * 6 + px[i * 4 + 2]) // 10
    starts = []
    if seeds:
        starts = [sy * w + sx for (sx, sy) in seeds]
    else:
        for x in range(w):
            starts += [x, (h - 1) * w + x]
        for y in range(h):
            starts += [y * w, y * w + w - 1]
    for s in starts:
        if (luma[s] >= min_luma or (pills and is_label_pill(px[s * 4], px[s * 4 + 1], px[s * 4 + 2]))) and not isbg[s]:
            isbg[s] = 1
            q.append(s)
    while q:
        p = q.popleft()
        x = p % w
        y = p // w
        r, g, b = px[p * 4], px[p * 4 + 1], px[p * 4 + 2]
        for nb in ((p - 1) if x > 0 else -1, (p + 1) if x < w - 1 else -1, (p - w) if y > 0 else -1, (p + w) if y < h - 1 else -1):
            if nb < 0 or isbg[nb]:
                continue
            nr, ng, nbl = px[nb * 4], px[nb * 4 + 1], px[nb * 4 + 2]
            if pills and (is_label_pill(nr, ng, nbl) or (is_label_pill(r, g, b) and luma[nb] >= min_luma)):
                isbg[nb] = 1
                q.append(nb)
                continue
            if luma[nb] < min_luma:
                continue
            if max(abs(nr - r), abs(ng - g), abs(nbl - b)) <= step:
                isbg[nb] = 1
                q.append(nb)
    return isbg


def components(isbg, w, h):
    comp = [0] * (w * h)
    info = [None]
    q = deque()
    for s in range(w * h):
        if not isbg[s] and comp[s] == 0:
            cid = len(info)
            comp[s] = cid
            q.append(s)
            n = 0
            x0 = x1 = s % w
            y0 = y1 = s // w
            while q:
                p = q.popleft()
                n += 1
                x = p % w
                y = p // w
                if x < x0:
                    x0 = x
                if x > x1:
                    x1 = x
                if y < y0:
                    y0 = y
                if y > y1:
                    y1 = y
                for dx, dy in ((1, 0), (-1, 0), (0, 1), (0, -1), (1, 1), (-1, -1), (1, -1), (-1, 1)):
                    nx = x + dx
                    ny = y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        k = ny * w + nx
                        if not isbg[k] and comp[k] == 0:
                            comp[k] = cid
                            q.append(k)
            info.append({"id": cid, "n": n, "box": (x0, y0, x1, y1)})
    return comp, info[1:]


def extract(px, w, h, isbg, comp, ids, pad=3):
    """RGBA cut-out of the given component ids, trimmed, backdrop un-mixed."""
    keep = set(ids)
    xs0, ys0, xs1, ys1 = w, h, -1, -1
    n = w * h
    for i in range(n):
        if comp[i] in keep:
            x = i % w
            y = i // w
            xs0 = min(xs0, x)
            xs1 = max(xs1, x)
            ys0 = min(ys0, y)
            ys1 = max(ys1, y)
    if xs1 < 0:
        return None
    ow = xs1 - xs0 + 1 + pad * 2
    oh = ys1 - ys0 + 1 + pad * 2
    out = bytearray(ow * oh * 4)
    for y in range(ys0, ys1 + 1):
        for x in range(xs0, xs1 + 1):
            i = y * w + x
            if comp[i] not in keep:
                continue
            r, g, b = px[i * 4], px[i * 4 + 1], px[i * 4 + 2]
            a = 255
            br = bg_n = 0
            bgc = [0, 0, 0]
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    nx = x + dx
                    ny = y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        k = ny * w + nx
                        if isbg[k]:
                            bg_n += 1
                            bgc[0] += px[k * 4]
                            bgc[1] += px[k * 4 + 1]
                            bgc[2] += px[k * 4 + 2]
                            if dx == 0 or dy == 0:
                                br += 1
            if br > 0:
                bgc = [c / bg_n for c in bgc]
                d = max(abs(r - bgc[0]), abs(g - bgc[1]), abs(b - bgc[2]))
                af = min(1.0, max(0.2, d / 80.0))
                r = int(min(255, max(0, (r - (1 - af) * bgc[0]) / af)))
                g = int(min(255, max(0, (g - (1 - af) * bgc[1]) / af)))
                b = int(min(255, max(0, (b - (1 - af) * bgc[2]) / af)))
                a = int(af * 255)
            t = ((y - ys0 + pad) * ow + (x - xs0 + pad)) * 4
            out[t] = r
            out[t + 1] = g
            out[t + 2] = b
            out[t + 3] = a
    return {"w": ow, "h": oh, "px": out, "box": (xs0, ys0, xs1, ys1)}


def cut_panel(sheet_name, rect, count=1, mode="flat", order="x", merge=0, min_size=60, **kw):
    """Returns `count` cut-outs from the rectangle (largest drawings first,
    then sorted by `order`: "x" left-to-right, "rows" reading order).
    merge > 0 also glues on smaller bits lying within that many pixels of a
    kept drawing (detached leaves, sparkles that belong to it)."""
    w, h, px = crop(sheet_name, rect)
    isbg = background_mask(px, w, h, mode=mode, **kw)
    comp, info = components(isbg, w, h)
    info = [c for c in info if c["n"] >= min_size]
    info.sort(key=lambda c: -c["n"])
    main = info[:count]
    rest = info[count:]
    if order == "rows":
        main.sort(key=lambda c: (c["box"][1] // 60, c["box"][0]))
    else:
        main.sort(key=lambda c: c["box"][0])
    out = []
    for m in main:
        ids = [m["id"]]
        if merge > 0:
            bx0, by0, bx1, by1 = m["box"]
            for r in rest:
                x0, y0, x1, y1 = r["box"]
                if x1 >= bx0 - merge and x0 <= bx1 + merge and y1 >= by0 - merge and y0 <= by1 + merge:
                    ids.append(r["id"])
        cut = extract(px, w, h, isbg, comp, ids)
        if cut:
            cut["origin"] = (rect[0] + cut["box"][0], rect[1] + cut["box"][1])
            out.append(cut)
    return out


def save(cut, path):
    os.makedirs(os.path.dirname(path), exist_ok=True)
    write_png(path, cut["w"], cut["h"], cut["px"])


def pad_to(cut, size, anchor="bottom"):
    """Centre a cut-out on a square canvas (bottom-anchored by default)."""
    w, h, px = cut["w"], cut["h"], cut["px"]
    out = bytearray(size * size * 4)
    ox = (size - w) // 2
    oy = size - h if anchor == "bottom" else (size - h) // 2
    for y in range(h):
        ty = y + oy
        if 0 <= ty < size:
            for x in range(w):
                tx = x + ox
                if 0 <= tx < size:
                    s = (y * w + x) * 4
                    t = (ty * size + tx) * 4
                    out[t:t + 4] = px[s:s + 4]
    return {"w": size, "h": size, "px": out}


def contact_sheet(cuts, path, cell=140, cols=8, bgc=(110, 160, 215)):
    rows = (len(cuts) + cols - 1) // cols
    W = cols * cell
    H = max(rows, 1) * cell
    img = bytearray(W * H * 4)
    for i in range(W * H):
        shade = 0 if ((i % W) // 20 + (i // W) // 20) % 2 == 0 else 12
        img[i * 4] = bgc[0] + shade
        img[i * 4 + 1] = bgc[1] + shade
        img[i * 4 + 2] = bgc[2] + shade
        img[i * 4 + 3] = 255
    for idx, c in enumerate(cuts):
        if c is None:
            continue
        fx = (idx % cols) * cell + max(0, (cell - c["w"]) // 2)
        fy = (idx // cols) * cell + max(0, (cell - c["h"]) // 2)
        for y in range(min(c["h"], cell)):
            for x in range(min(c["w"], cell)):
                s = (y * c["w"] + x) * 4
                a = c["px"][s + 3]
                if a:
                    t = ((fy + y) * W + fx + x) * 4
                    for k in range(3):
                        img[t + k] = (c["px"][s + k] * a + img[t + k] * (255 - a)) // 255
    os.makedirs(os.path.dirname(path), exist_ok=True)
    write_png(path, W, H, img)


def cut_all(sheet_name, rect, mode="flat", min_size=70, gap=5, **kw):
    """Every drawing in the rectangle, left to right. Name tags, thin frame
    lines and near-empty outlines are thrown away; bits closer than `gap`
    pixels are treated as one drawing."""
    w, h, px = crop(sheet_name, rect)
    isbg = background_mask(px, w, h, mode=mode, **kw)
    comp, info = components(isbg, w, h)
    good = []
    for c in info:
        x0, y0, x1, y1 = c["box"]
        bw = x1 - x0 + 1
        bh = y1 - y0 + 1
        if c["n"] < 12 or min(bw, bh) <= 5:
            continue
        if c["n"] / float(bw * bh) < 0.2 and max(bw, bh) > 40:
            continue                      # a frame line
        # average colour: name tags are flat plum
        tot = [0, 0, 0]
        cnt = 0
        for y in range(y0, y1 + 1, 2):
            for x in range(x0, x1 + 1, 2):
                i = y * w + x
                if comp[i] == c["id"]:
                    tot[0] += px[i * 4]
                    tot[1] += px[i * 4 + 1]
                    tot[2] += px[i * 4 + 2]
                    cnt += 1
        if cnt:
            r, g, b = (t // cnt for t in tot)
            if is_label_pill(r, g, b) and bw > bh * 1.6:
                continue
        good.append(c)
    # glue neighbours together
    groups = []
    for c in sorted(good, key=lambda c: -c["n"]):
        placed = False
        for grp in groups:
            bx0, by0, bx1, by1 = grp["box"]
            x0, y0, x1, y1 = c["box"]
            if x1 >= bx0 - gap and x0 <= bx1 + gap and y1 >= by0 - gap and y0 <= by1 + gap:
                grp["ids"].append(c["id"])
                grp["n"] += c["n"]
                grp["box"] = (min(bx0, x0), min(by0, y0), max(bx1, x1), max(by1, y1))
                placed = True
                break
        if not placed:
            groups.append({"ids": [c["id"]], "n": c["n"], "box": c["box"]})
    groups = [g for g in groups if g["n"] >= min_size]
    groups.sort(key=lambda g: g["box"][0])
    out = []
    for g in groups:
        cut = extract(px, w, h, isbg, comp, g["ids"])
        if cut:
            cut["origin"] = (rect[0] + cut["box"][0], rect[1] + cut["box"][1])
            out.append(cut)
    return out


def trim_thin(cut, min_run=5):
    """Clears stray hairlines hanging off a cut-out (rows / columns that hold
    fewer than `min_run` solid pixels at the outer edges)."""
    w, h, px = cut["w"], cut["h"], cut["px"]
    cols = [sum(1 for y in range(h) if px[(y * w + x) * 4 + 3] > 40) for x in range(w)]
    rows = [sum(1 for x in range(w) if px[(y * w + x) * 4 + 3] > 40) for y in range(h)]
    x0 = 0
    while x0 < w and cols[x0] < min_run:
        x0 += 1
    x1 = w - 1
    while x1 > x0 and cols[x1] < min_run:
        x1 -= 1
    y0 = 0
    while y0 < h and rows[y0] < min_run:
        y0 += 1
    y1 = h - 1
    while y1 > y0 and rows[y1] < min_run:
        y1 -= 1
    nw = x1 - x0 + 1
    nh = y1 - y0 + 1
    if nw <= 0 or nh <= 0:
        return cut
    out = bytearray(nw * nh * 4)
    for y in range(nh):
        s = ((y + y0) * w + x0) * 4
        out[y * nw * 4:(y + 1) * nw * 4] = px[s:s + nw * 4]
    return {"w": nw, "h": nh, "px": out, "box": cut.get("box"), "origin": cut.get("origin")}


def strip_white(cut, level=236):
    """Removes leftover panel-white that hangs on the outside of a cut-out
    (white reached from the transparent surround, never white enclosed by
    the drawing's own outline)."""
    w, h, px = cut["w"], cut["h"], cut["px"]
    seen = bytearray(w * h)
    q = deque()
    for i in range(w * h):
        if px[i * 4 + 3] == 0:
            seen[i] = 1
            q.append(i)
    while q:
        p = q.popleft()
        x = p % w
        y = p // w
        for nb in ((p - 1) if x > 0 else -1, (p + 1) if x < w - 1 else -1, (p - w) if y > 0 else -1, (p + w) if y < h - 1 else -1):
            if nb < 0 or seen[nb]:
                continue
            a = px[nb * 4 + 3]
            if a < 255 or (px[nb * 4] >= level and px[nb * 4 + 1] >= level and px[nb * 4 + 2] >= level):
                seen[nb] = 1
                if a == 255 or (px[nb * 4] >= level and px[nb * 4 + 1] >= level and px[nb * 4 + 2] >= level):
                    px[nb * 4 + 3] = 0
                    q.append(nb)
    return cut


def keep_main(cut, min_frac=0.07, min_fill=0.24):
    """Drops debris from a cut-out: specks much smaller than the main drawing,
    hairlines, and hollow frames (bits of a panel border). Then trims."""
    w, h, px = cut["w"], cut["h"], cut["px"]
    label = [0] * (w * h)
    comps = []          # [area, x0, y0, x1, y1]
    for start in range(w * h):
        if label[start] or px[start * 4 + 3] <= 110:
            continue
        cid = len(comps) + 1
        label[start] = cid
        q = deque([start])
        area, x0, y0, x1, y1 = 0, w, h, -1, -1
        while q:
            p = q.popleft()
            x, y = p % w, p // w
            area += 1
            x0, x1, y0, y1 = min(x0, x), max(x1, x), min(y0, y), max(y1, y)
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        k = ny * w + nx
                        if not label[k] and px[k * 4 + 3] > 110:
                            label[k] = cid
                            q.append(k)
        comps.append([area, x0, y0, x1, y1])
    if not comps:
        return cut
    # the main drawing: the biggest component that is not a hollow frame
    def solid(c):
        bw, bh = c[3] - c[1] + 1, c[4] - c[2] + 1
        return min(bw, bh) > 5 and c[0] / float(bw * bh) >= min_fill
    solids = [c for c in comps if solid(c)]
    if not solids:
        return cut
    biggest = max(c[0] for c in solids)
    keep = set()
    for i, c in enumerate(comps):
        if solid(c) and c[0] >= biggest * min_frac:
            keep.add(i + 1)
    x0, y0, x1, y1 = w, h, -1, -1
    for i in range(w * h):
        x, y = i % w, i // w
        if label[i] in keep:
            x0, x1, y0, y1 = min(x0, x), max(x1, x), min(y0, y), max(y1, y)
        elif label[i]:
            px[i * 4 + 3] = 0
        elif px[i * 4 + 3] > 0:
            # a soft edge pixel: keep it only beside a kept drawing
            near = False
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h and label[ny * w + nx] in keep:
                        near = True
            if not near:
                px[i * 4 + 3] = 0
    pad = 2
    x0, y0, x1, y1 = max(0, x0 - pad), max(0, y0 - pad), min(w - 1, x1 + pad), min(h - 1, y1 + pad)
    nw, nh = x1 - x0 + 1, y1 - y0 + 1
    out = bytearray(nw * nh * 4)
    for y in range(nh):
        s = ((y + y0) * w + x0) * 4
        out[y * nw * 4:(y + 1) * nw * 4] = px[s:s + nw * 4]
    return {"w": nw, "h": nh, "px": out, "box": cut.get("box"), "origin": cut.get("origin")}


def _framey(r, g, b):
    """The soft mauve of the boards' panel borders."""
    return 125 <= r <= 220 and g >= 90 and r - g >= 12 and abs(r - b) <= 36


def strip_lines(cut, min_len=20, max_thick=3):
    """Clears long, straight, hair-thin mauve lines (pieces of a panel border
    that came along with a drawing). Thick or differently coloured straight
    edges (blocks, poles, planks) are left alone."""
    w, h, px = cut["w"], cut["h"], cut["px"]

    def solid(x, y):
        return 0 <= x < w and 0 <= y < h and px[(y * w + x) * 4 + 3] > 60

    def thick(x, y, dx, dy):
        n = 1
        k = 1
        while solid(x + dx * k, y + dy * k):
            n += 1
            k += 1
        k = 1
        while solid(x - dx * k, y - dy * k):
            n += 1
            k += 1
        return n

    doomed = set()
    for horizontal in (True, False):
        outer, inner = (h, w) if horizontal else (w, h)
        for o in range(outer):
            run = []
            for i in range(inner + 1):
                x, y = (i, o) if horizontal else (o, i)
                ok = False
                if i < inner and solid(x, y):
                    r, g, b = px[(y * w + x) * 4], px[(y * w + x) * 4 + 1], px[(y * w + x) * 4 + 2]
                    t = thick(x, y, 0, 1) if horizontal else thick(x, y, 1, 0)
                    ok = t <= max_thick and _framey(r, g, b)
                if ok:
                    run.append((x, y))
                else:
                    if len(run) >= min_len:
                        for (rx, ry) in run:
                            for k in range(-max_thick, max_thick + 1):
                                nx, ny = (rx, ry + k) if horizontal else (rx + k, ry)
                                if solid(nx, ny) or (0 <= nx < w and 0 <= ny < h):
                                    # only the thin line itself: stop at gaps
                                    pass
                            doomed.add((rx, ry))
                    run = []
    # take the whole thickness of each doomed line pixel
    extra = set()
    for (x, y) in doomed:
        for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            nx, ny = x + dx, y + dy
            if 0 <= nx < w and 0 <= ny < h and px[(ny * w + nx) * 4 + 3] > 0:
                r, g, b = px[(ny * w + nx) * 4], px[(ny * w + nx) * 4 + 1], px[(ny * w + nx) * 4 + 2]
                if px[(ny * w + nx) * 4 + 3] <= 200 or _framey(r, g, b):
                    extra.add((nx, ny))
    for (x, y) in doomed | extra:
        px[(y * w + x) * 4 + 3] = 0
    return cut


def split_parts(cut, min_frac=0.07):
    """Splits a cut-out that holds several separate drawings (a row of small
    treats that sat close together) into one cut-out each, left to right."""
    w, h, px = cut["w"], cut["h"], cut["px"]
    label = [0] * (w * h)
    comps = []
    for start in range(w * h):
        if label[start] or px[start * 4 + 3] <= 110:
            continue
        cid = len(comps) + 1
        label[start] = cid
        q = deque([start])
        area, x0, y0, x1, y1 = 0, w, h, -1, -1
        while q:
            p = q.popleft()
            x, y = p % w, p // w
            area += 1
            x0, x1, y0, y1 = min(x0, x), max(x1, x), min(y0, y), max(y1, y)
            for dy in (-1, 0, 1):
                for dx in (-1, 0, 1):
                    nx, ny = x + dx, y + dy
                    if 0 <= nx < w and 0 <= ny < h:
                        k = ny * w + nx
                        if not label[k] and px[k * 4 + 3] > 110:
                            label[k] = cid
                            q.append(k)
        comps.append([area, x0, y0, x1, y1, cid])
    if len(comps) < 2:
        return [cut]
    biggest = max(c[0] for c in comps)
    parts = []
    for area, x0, y0, x1, y1, cid in sorted([c for c in comps if c[0] >= biggest * min_frac], key=lambda c: c[1]):
        pad = 2
        bx0, by0, bx1, by1 = max(0, x0 - pad), max(0, y0 - pad), min(w - 1, x1 + pad), min(h - 1, y1 + pad)
        nw, nh = bx1 - bx0 + 1, by1 - by0 + 1
        out = bytearray(nw * nh * 4)
        for y in range(by0, by1 + 1):
            for x in range(bx0, bx1 + 1):
                i = y * w + x
                mine = label[i] == cid
                if not mine and label[i] == 0 and px[i * 4 + 3] > 0:
                    for dy in (-1, 0, 1):
                        for dx in (-1, 0, 1):
                            nx, ny = x + dx, y + dy
                            if 0 <= nx < w and 0 <= ny < h and label[ny * w + nx] == cid:
                                mine = True
                if mine:
                    t = ((y - by0) * nw + (x - bx0)) * 4
                    out[t:t + 4] = px[i * 4:i * 4 + 4]
        parts.append({"w": nw, "h": nh, "px": out, "box": cut.get("box"), "origin": cut.get("origin")})
    return parts
