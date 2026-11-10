"""Parallax scenery per world: clouds, a far layer and a middle layer.
Soft shapes without outlines so the play space in front always reads first.
Each strip tiles left-to-right (its two ends meet at the same height)."""
import math
import os
import random
from svgkit import SVG, mix, darken, lighten, f, smooth_closed

W = 1024


def hills(svg, base_y, amp, color, seed, bumps=4, height=None):
    """A band of rolling hills that tiles horizontally."""
    h = height or svg.h
    rnd = random.Random(seed)
    phases = [(rnd.uniform(0, math.tau), rnd.choice([1, 2, 3])) for _ in range(3)]
    pts = []
    n = 64
    for i in range(n + 1):
        x = W * i / n
        y = base_y
        for k, (ph, freq) in enumerate(phases):
            y += math.sin(2 * math.pi * freq * (i / n) + ph) * amp / (k + 1.2)
        pts.append((x, y))
    d = "M0 %s " % f(h + 2) + " ".join("L%s %s" % (f(x), f(y)) for x, y in pts) + " L%d %s Z" % (W, f(h + 2))
    svg.path(d, fill=color)
    return pts


def cloud(svg, cx, cy, s, color="#ffffff", opacity=0.9):
    for (dx, dy, r) in ((-46, 8, 26), (-18, -8, 34), (18, -4, 30), (46, 10, 24), (0, 14, 30)):
        svg.circle(cx + dx * s, cy + dy * s, r * s, color, opacity=opacity)
    svg.rect(cx - 60 * s, cy + 12 * s, 120 * s, 24 * s, color, rx=12 * s, opacity=opacity)


def clouds_strip(theme, tint="#ffffff", opacity=0.9, seed=3):
    svg = SVG(W, 300)
    rnd = random.Random(seed)
    # positions chosen so nothing crosses the seam at x=0 / x=1024
    for (x, y, sc) in ((150, 90, 1.0), (430, 170, 0.75), (700, 70, 1.2), (900, 200, 0.7)):
        cloud(svg, x, y + rnd.uniform(-10, 10), sc, tint, opacity)
    return svg


def tree(svg, x, y, s, leaf, trunk):
    svg.rect(x - 6 * s, y - 36 * s, 12 * s, 40 * s, trunk, rx=4 * s)
    svg.circle(x, y - 62 * s, 34 * s, leaf)
    svg.circle(x - 22 * s, y - 44 * s, 24 * s, leaf)
    svg.circle(x + 22 * s, y - 44 * s, 24 * s, leaf)
    svg.circle(x - 8 * s, y - 70 * s, 12 * s, lighten(leaf, 0.2), opacity=0.7)


def windmill(svg, x, y, s, body, blade):
    svg.poly([(x - 22 * s, y), (x - 14 * s, y - 90 * s), (x + 14 * s, y - 90 * s), (x + 22 * s, y)], body)
    svg.poly([(x - 18 * s, y - 90 * s), (x, y - 112 * s), (x + 18 * s, y - 90 * s)], darken(body, 0.15))
    for a in (20, 110, 200, 290):
        r = math.radians(a)
        ex, ey = x + math.cos(r) * 62 * s, y - 94 * s + math.sin(r) * 62 * s
        px, py = -math.sin(r) * 9 * s, math.cos(r) * 9 * s
        svg.poly([(x, y - 94 * s), (ex + px, ey + py), (ex - px, ey - py)], blade, opacity=0.9)


def picnic():
    far = SVG(W, 420)
    hills(far, 210, 46, "#a9dcc0", 11)
    for (x, sc) in ((180, 1.0), (640, 0.8)):
        windmill(far, x, 236 if x == 180 else 250, sc, "#c9e6d4", "#e6f5ea")
    hills(far, 290, 34, "#93d1a8", 12)
    mid = SVG(W, 380)
    pts = hills(mid, 170, 30, "#7fcf7a", 21)
    for (x, sc) in ((90, 0.9), (330, 1.15), (560, 0.8), (800, 1.05), (960, 0.7)):
        y = pts[int(x / W * 64)][1] + 6
        tree(mid, x, y, sc, "#58b86a", "#8a6a4a")
    hills(mid, 250, 22, "#6cc56f", 22)
    # picnic cloth patches
    for (x, y) in ((240, 300), (700, 318)):
        mid.poly([(x - 40, y), (x + 40, y - 6), (x + 52, y + 18), (x - 28, y + 24)], "#f7b2a8", opacity=0.75)
        mid.poly([(x - 20, y - 1.5), (x, y - 3), (x + 12, y + 21), (x - 8, y + 22.5)], "#ffffff", opacity=0.55)
    return {"far": far, "mid": mid, "clouds": clouds_strip("picnic")}


def nest():
    far = SVG(W, 420)
    hills(far, 220, 40, "#bfe3c8", 31)
    hills(far, 300, 30, "#a8d8b4", 32)
    mid = SVG(W, 380)
    pts = hills(mid, 180, 26, "#8fd58a", 41)
    for (x, sc) in ((140, 1.1), (470, 0.9), (780, 1.2)):
        tree(mid, x, pts[int(x / W * 64)][1] + 6, sc, "#6cc56f", "#8a6a4a")
    hills(mid, 260, 20, "#7fcf7a", 42)
    return {"far": far, "mid": mid, "clouds": clouds_strip("nest", "#fff7ea")}


THEMES = {"picnic": picnic, "nest": nest}


def make_all(assets):
    out = []
    for theme, fn in THEMES.items():
        layers = fn()
        for layer, svg in layers.items():
            path = os.path.join(assets, "sprites", "bg", "%s_%s.svg" % (theme, layer))
            svg.save(path)
            out.append(path)
    return out
