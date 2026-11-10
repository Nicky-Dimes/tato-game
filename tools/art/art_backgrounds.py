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


def pine(svg, x, y, s, color):
    for i, (w, h) in enumerate(((46, 50), (36, 44), (26, 38))):
        top = y - 24 * s - i * 26 * s
        svg.poly([(x - w * s, top + h * s * 0.55), (x, top - h * s * 0.45), (x + w * s, top + h * s * 0.55)], color)
    svg.rect(x - 5 * s, y - 26 * s, 10 * s, 30 * s, darken(color, 0.3))


def tent(svg, x, y, s, a, b):
    svg.poly([(x - 60 * s, y), (x - 60 * s, y - 50 * s), (x, y - 110 * s), (x + 60 * s, y - 50 * s), (x + 60 * s, y)], a)
    for i in range(-2, 3, 2):
        svg.poly([(x + i * 20 * s - 10 * s, y), (x + i * 20 * s - 10 * s, y - 50 * s), (x, y - 110 * s), (x + i * 20 * s + 10 * s, y - 50 * s), (x + i * 20 * s + 10 * s, y)], b, opacity=0.8)
    svg.poly([(x, y - 110 * s), (x, y - 134 * s), (x + 18 * s, y - 124 * s)], b)


def castle(svg, x, y, s, color):
    svg.rect(x - 70 * s, y - 90 * s, 140 * s, 90 * s, color)
    for dx in (-70, -20, 30):
        svg.rect(x + dx * s, y - 104 * s, 30 * s, 16 * s, color)
    for dx, h in ((-88, 150), (58, 170)):
        svg.rect(x + dx * s, y - h * s, 30 * s, h * s, color)
        svg.poly([(x + (dx - 6) * s, y - h * s), (x + (dx + 15) * s, y - (h + 40) * s), (x + (dx + 36) * s, y - h * s)], darken(color, 0.12))


def layers(far_a, far_b, mid_a, mid_b, deco, cloud_tint="#ffffff", seed=1):
    far = SVG(W, 420)
    pts = hills(far, 210, 46, far_a, seed * 10 + 1)
    deco(far, pts, "far")
    hills(far, 290, 34, far_b, seed * 10 + 2)
    mid = SVG(W, 380)
    pts = hills(mid, 170, 30, mid_a, seed * 10 + 3)
    deco(mid, pts, "mid")
    hills(mid, 250, 22, mid_b, seed * 10 + 4)
    return {"far": far, "mid": mid, "clouds": clouds_strip("x", cloud_tint)}


def at(pts, x):
    return pts[int(x / W * 64)][1] + 6


def grassland():
    def deco(svg, pts, layer):
        if layer == "far":
            for (x, sc) in ((180, 1.0), (660, 0.8)):
                windmill(svg, x, at(pts, x) + 20, sc, "#c9e6d4", "#e6f5ea")
        else:
            for (x, sc) in ((90, 0.9), (330, 1.15), (560, 0.8), (800, 1.05), (960, 0.7)):
                tree(svg, x, at(pts, x), sc, "#58b86a", "#8a6a4a")
    return layers("#a9dcc0", "#93d1a8", "#7fcf7a", "#6cc56f", deco, seed=1)


def orchard():
    def deco(svg, pts, layer):
        xs = ((120, 1.1), (400, 0.9), (700, 1.2), (920, 0.8)) if layer == "mid" else ((260, 0.8), (560, 0.9), (860, 0.7))
        for (x, sc) in xs:
            y = at(pts, x)
            tree(svg, x, y, sc, "#4fae5a" if layer == "mid" else "#8fcf9a", "#8a6a4a")
            if layer == "mid":
                for (dx, dy) in ((-18, -52), (14, -66), (22, -40), (-6, -78)):
                    svg.circle(x + dx * sc, y + dy * sc, 6 * sc, "#e0392e")
    return layers("#b5dfb0", "#9fd39a", "#86cf72", "#74c462", deco, seed=2)


def candy():
    def deco(svg, pts, layer):
        if layer == "far":
            cx, cy = 300, at(pts, 300) - 90
            svg.circle(cx, cy, 80, "none", stroke="#f7b9dc", sw=8)
            for a in range(0, 360, 45):
                r = math.radians(a)
                svg.line(cx, cy, cx + math.cos(r) * 80, cy + math.sin(r) * 80, "#f7b9dc", 4)
                svg.circle(cx + math.cos(r) * 80, cy + math.sin(r) * 80, 10, "#ffd98a")
            tent(svg, 760, at(pts, 760) + 10, 0.9, "#f7b9dc", "#fff0f7")
        else:
            tent(svg, 180, at(pts, 180), 1.0, "#ff8fc4", "#fff0c4")
            tent(svg, 640, at(pts, 640), 0.8, "#b58cf5", "#ffe6f4")
            for x in (420, 900):
                y = at(pts, x)
                svg.rect(x - 4, y - 70, 8, 74, "#ffffff")
                svg.circle(x, y - 84, 24, "#ff8fc4")
                svg.circle(x, y - 84, 12, "#ffffff", opacity=0.8)
    return layers("#f5c6e6", "#eeb0da", "#f79ac8", "#f285bb", deco, "#fff0f8", seed=3)


def icy():
    def deco(svg, pts, layer):
        if layer == "far":
            for (x, sc) in ((140, 1.3), (460, 1.0), (820, 1.4)):
                svg.poly([(x - 120 * sc, at(pts, x) + 60), (x, at(pts, x) - 150 * sc), (x + 120 * sc, at(pts, x) + 60)], "#d3e6fa")
                svg.poly([(x - 34 * sc, at(pts, x) - 108 * sc), (x, at(pts, x) - 150 * sc), (x + 34 * sc, at(pts, x) - 108 * sc)], "#ffffff")
        else:
            for (x, sc) in ((100, 1.0), (300, 0.8), (540, 1.1), (760, 0.9), (940, 1.0)):
                pine(svg, x, at(pts, x), sc, "#5f9fb8")
    return layers("#c5ddf5", "#b2d0ee", "#e4f2fc", "#d3e8f8", deco, seed=4)


def windy():
    def deco(svg, pts, layer):
        if layer == "far":
            for (x, sc) in ((200, 1.1), (520, 0.8), (840, 1.0)):
                windmill(svg, x, at(pts, x) + 20, sc, "#d6ead0", "#eef7ea")
        else:
            for (x, sc) in ((120, 0.9), (640, 1.0), (930, 0.8)):
                tree(svg, x, at(pts, x), sc, "#6fc45a", "#8a6a4a")
            windmill(svg, 380, at(pts, 380) + 10, 1.5, "#f0dcc0", "#fff3e0")
    return layers("#b9e3c4", "#a4d8b0", "#93d877", "#80cd66", deco, seed=5)


def castle_theme():
    def deco(svg, pts, layer):
        if layer == "far":
            castle(svg, 300, at(pts, 300) + 30, 1.3, "#b5a6d6")
            castle(svg, 780, at(pts, 780) + 30, 1.0, "#bdb0dc")
        else:
            castle(svg, 560, at(pts, 560) + 10, 1.1, "#8f7fb8")
            for x in (140, 900):
                y = at(pts, x)
                svg.rect(x - 4, y - 120, 8, 124, "#6b5c94")
                svg.poly([(x + 4, y - 120), (x + 50, y - 104), (x + 4, y - 86)], "#e0392e")
    return layers("#cfc3ea", "#c0b2e2", "#a99ad0", "#9a8ac6", deco, "#f6eefc", seed=6)


def nest():
    def deco(svg, pts, layer):
        if layer == "mid":
            for (x, sc) in ((140, 1.1), (470, 0.9), (780, 1.2)):
                tree(svg, x, at(pts, x), sc, "#6cc56f", "#8a6a4a")
    return layers("#bfe3c8", "#a8d8b4", "#8fd58a", "#7fcf7a", deco, "#fff7ea", seed=7)


THEMES = {"grassland": grassland, "orchard": orchard, "candy": candy, "icy": icy, "windy": windy, "castle": castle_theme, "nest": nest}


def make_all(assets):
    out = []
    for theme, fn in THEMES.items():
        layers = fn()
        for layer, svg in layers.items():
            path = os.path.join(assets, "sprites", "bg", "%s_%s.svg" % (theme, layer))
            svg.save(path)
            out.append(path)
    return out
