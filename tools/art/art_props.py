"""Stage furniture, pickups, small effects and UI glyphs.
Everything is authored at 2x (one 64 px game cell = 128 px here) and shown
at half scale. Standing props are drawn with their base on the bottom edge
of the canvas, centred, because the game anchors them bottom-centre."""
import math
import os
from svgkit import (SVG, OUTLINE, OUTLINE_W, mix, darken, lighten, f, blob_path, soft_body,
                    gloss, star_path, smooth_closed, rounded_poly, eye, blush, ground_shadow)

O = OUTLINE
SW = OUTLINE_W
WOOD = "#d9a066"
WOOD_D = "#b57a44"
WOOD_L = "#f3c88a"
GOLD = "#ffcf3f"
GOLD_D = "#e89a1a"


def wood_rect(svg, x, y, w, h, rx=8, base=WOOD):
    svg.rect(x, y, w, h, svg.linear([(0, lighten(base, 0.18)), (1, darken(base, 0.1))]), rx=rx, stroke=O, sw=SW)


# ---------------------------------------------------------------- pickups --

def crumb():
    s = SVG(56, 56)
    s.path(rounded_poly([(12, 22), (26, 8), (44, 16), (48, 36), (32, 48), (14, 42)], 8), fill=s.radial([(0, "#ffe9a8"), (1, GOLD_D)], 0.35, 0.3, 0.8), stroke=O, sw=4.5)
    s.circle(22, 22, 4, "#ffffff", opacity=0.85)
    s.circle(34, 32, 2.5, darken(GOLD_D, 0.25))
    return s


def scrap():
    s = SVG(96, 96)
    pts = [(18, 16), (70, 10), (84, 30), (78, 84), (24, 88), (12, 60)]
    s.path(rounded_poly(pts, 6), fill=s.linear([(0, "#fffaf0"), (1, "#f3e2c4")]), stroke=O, sw=SW)
    s.poly([(70, 10), (84, 30), (68, 28)], "#e6d2ae", stroke=O, sw=4)
    for y, x1, x2 in ((36, 26, 62), (48, 24, 68), (60, 26, 56)):
        s.line(x1, y, x2, y, "#c9a877", 4)
    s.path(star_path(60, 68, 12, 5.5), fill=GOLD, stroke=O, sw=3.5)
    return s


def pin():
    s = SVG(96, 96)
    s.circle(48, 48, 36, s.radial([(0, "#bfe9ff"), (1, "#58b8f5")], 0.38, 0.3, 0.8), stroke=O, sw=SW)
    s.circle(48, 48, 27, "none", stroke="#ffffff", sw=4, opacity=0.8)
    # tiny goose head
    s.circle(46, 50, 15, "#fffaf0", stroke=O, sw=4)
    s.poly([(58, 48), (72, 52), (58, 58)], "#ff9a1f", stroke=O, sw=3.5)
    s.circle(50, 46, 3.4, "#3a1f4d")
    s.path("M40 36 l4 -8 l4 7", stroke=O, sw=3.5)
    s.ellipse(34, 30, 8, 4, "#ffffff", opacity=0.7, rot=-30)
    return s


def dish():
    s = SVG(104, 96)
    s.ellipse(52, 76, 44, 10, "#fff3d6", stroke=O, sw=SW)
    s.path("M14 72 A38 38 0 0 1 90 72 Z", fill=s.linear([(0, "#f1f4ff"), (1, "#a9b3d6")]), stroke=O, sw=SW)
    s.circle(52, 30, 8, s.radial([(0, "#ffe9a8"), (1, GOLD_D)], 0.35, 0.3, 0.8), stroke=O, sw=4)
    s.path("M26 60 A28 28 0 0 1 44 40", stroke="#ffffff", sw=6, opacity=0.75)
    s.path(star_path(66, 58, 9, 4), fill=GOLD, stroke=O, sw=3)
    return s


def feather():
    s = SVG(88, 88)
    d = "M18 74 C10 44 26 16 58 10 C78 12 80 34 66 50 C54 64 38 72 18 74 Z"
    s.path(d, fill=s.linear([(0, "#ffffff"), (1, "#f6d9ee")], 0, 0, 1, 1), stroke=O, sw=SW)
    s.path("M20 72 C34 54 46 38 62 22", stroke="#dcc7f0", sw=4)
    s.path("M34 52 l-10 -4 M44 40 l-11 -3 M52 30 l-9 -4", stroke="#dcc7f0", sw=3.5)
    s.path("M12 80 L22 68", stroke=O, sw=SW)
    return s


# ------------------------------------------------------------------ props --

def bowl():
    s = SVG(150, 76)
    ground_shadow(s, 75, 70, 62, 7)
    s.path("M14 22 H136 C136 52 112 66 75 66 C38 66 14 52 14 22 Z", fill=s.linear([(0, "#fffaf0"), (1, "#f0d9b8")]), stroke=O, sw=SW)
    s.ellipse(75, 22, 61, 11, "#ffe9c4", stroke=O, sw=SW)
    s.path("M24 40 Q75 58 126 40", stroke="#f5a2a8", sw=6)
    s.rect(54, 62, 42, 10, "#e6c9a0", rx=5, stroke=O, sw=4)
    return s


def station():
    s = SVG(120, 220)
    ground_shadow(s, 60, 212, 46, 7)
    wood_rect(s, 52, 20, 16, 190, 6)
    # basket nest at the foot
    s.path("M18 170 H102 L94 210 H26 Z", fill=s.linear([(0, "#e8b97a"), (1, "#c08a4c")]), stroke=O, sw=SW)
    for x in (36, 52, 68, 84):
        s.line(x, 174, x - 2, 206, "#a9722f", 3)
    s.line(22, 186, 98, 186, "#a9722f", 3)
    s.ellipse(60, 170, 44, 9, "#f6dba8", stroke=O, sw=SW)
    s.circle(60, 18, 10, GOLD, stroke=O, sw=4)
    return s


def station_flag():
    s = SVG(120, 220)
    s.path("M68 34 L116 52 L68 76 Z", fill=s.linear([(0, "#ffe27a"), (1, "#ff9a1f")], 0, 0, 1, 0), stroke=O, sw=SW)
    s.path("M80 50 q8 -6 14 2 q-8 6 -14 -2", fill="#ffffff", opacity=0.9)
    return s


def exit_bell():
    s = SVG(200, 270)
    ground_shadow(s, 100, 262, 84, 8)
    wood_rect(s, 22, 60, 22, 204, 8)
    wood_rect(s, 156, 60, 22, 204, 8)
    s.path("M14 70 Q100 -6 186 70 L176 86 Q100 22 24 86 Z", fill=s.linear([(0, "#ff8a7a"), (1, "#e0452e")]), stroke=O, sw=SW)
    for i in range(5):
        x = 44 + i * 28
        y = 62 - math.sin(i / 4.0 * math.pi) * 26
        s.circle(x, y, 6, "#fff3d6", stroke=O, sw=3)
    s.line(100, 44, 100, 84, O, SW)
    bell = "M56 170 C56 120 70 92 100 92 C130 92 144 120 144 170 L156 190 H44 Z"
    s.path(bell, fill=s.radial([(0, "#fff0a8"), (0.6, GOLD), (1, GOLD_D)], 0.36, 0.3, 0.85), stroke=O, sw=SW + 1)
    s.path("M72 150 C72 124 82 108 96 104", stroke="#ffffff", sw=8, opacity=0.7)
    s.circle(100, 200, 13, s.radial([(0, "#ffe9a8"), (1, GOLD_D)], 0.35, 0.3, 0.8), stroke=O, sw=SW)
    s.path("M86 86 Q100 70 114 86 Z", fill="#f5a2a8", stroke=O, sw=4)
    return s


def sign():
    s = SVG(120, 150)
    ground_shadow(s, 60, 144, 32, 5)
    wood_rect(s, 52, 60, 16, 86, 5)
    s.path(rounded_poly([(10, 14), (110, 10), (112, 72), (8, 76)], 12), fill=s.linear([(0, WOOD_L), (1, WOOD)]), stroke=O, sw=SW)
    s.path("M52 30 q8 -10 16 0 q4 10 -8 16 v6", stroke=O, sw=7)
    s.circle(60, 64, 4.5, O)
    return s


def thorns():
    s = SVG(128, 72)
    pts = [(6, 72), (10, 46), (28, 30), (48, 40), (64, 24), (82, 40), (102, 30), (118, 48), (122, 72)]
    s.path(smooth_closed(pts, 0.6), fill=s.linear([(0, "#6aa860"), (1, "#3d7a4a")]), stroke=O, sw=SW)
    for (x, y, dx, dy) in ((20, 34, -8, -22), (44, 34, 2, -26), (66, 22, 0, -20), (88, 34, 4, -26), (108, 34, 10, -22)):
        s.poly([(x - 7, y + 8), (x + dx, y + dy), (x + 7, y + 8)], "#ffd9e4", stroke=O, sw=4)
    for (x, y) in ((34, 56), (64, 50), (92, 58)):
        s.circle(x, y, 4, "#2f6140")
    return s


def chime():
    s = SVG(110, 130)
    s.line(55, 4, 55, 34, O, SW)
    s.path("M26 30 H84 L78 44 H32 Z", fill=WOOD, stroke=O, sw=4)
    body = "M28 96 C28 64 38 46 55 46 C72 46 82 64 82 96 L90 108 H20 Z"
    s.path(body, fill=s.radial([(0, "#fff0a8"), (0.6, GOLD), (1, GOLD_D)], 0.36, 0.3, 0.85), stroke=O, sw=SW)
    s.path("M40 84 C40 68 46 58 53 54", stroke="#ffffff", sw=6, opacity=0.7)
    s.circle(55, 114, 9, GOLD_D, stroke=O, sw=4)
    return s


def bell():
    s = SVG(160, 170)
    s.rect(60, 2, 40, 26, "#8a93b0", rx=8, stroke=O, sw=SW)
    body = "M30 124 C30 70 48 36 80 36 C112 36 130 70 130 124 L146 146 H14 Z"
    s.path(body, fill=s.radial([(0, "#e9c7a0"), (0.6, "#b9825a"), (1, "#7d5238")], 0.36, 0.3, 0.85), stroke=O, sw=SW + 1)
    s.path("M50 110 C50 84 60 62 76 54", stroke="#ffffff", sw=8, opacity=0.5)
    s.path("M20 132 H140", stroke="#7d5238", sw=6)
    s.circle(80, 152, 12, "#7d5238", stroke=O, sw=SW)
    s.path("M100 60 l-12 22 h12 l-8 20", stroke="#ffe34d", sw=5)
    return s


def gate():
    s = SVG(84, 128)
    s.rect(6, -6, 72, 140, s.linear([(0, "#b7bfdc"), (0.5, "#e2e7fa"), (1, "#8a93b0")], 0, 0, 1, 0), stroke=O, sw=SW)
    s.poly([(12, 28), (42, 8), (72, 28), (72, 48), (42, 28), (12, 48)], GOLD, stroke=O, sw=4)
    s.poly([(12, 88), (42, 68), (72, 88), (72, 108), (42, 88), (12, 108)], GOLD, stroke=O, sw=4)
    for y in (58, 120):
        s.circle(18, y, 4, "#6e7794")
        s.circle(66, y, 4, "#6e7794")
    return s


def plate(heavy=False):
    s = SVG(128, 44)
    s.rect(4, 24, 120, 18, "#8a93b0", rx=7, stroke=O, sw=SW)
    col = "#7a4fcf" if heavy else "#f0452e"
    s.path("M20 26 Q20 6 40 6 H88 Q108 6 108 26 Z", fill=s.linear([(0, lighten(col, 0.3)), (1, col)]), stroke=O, sw=SW)
    s.path("M34 14 H74", stroke="#ffffff", sw=5, opacity=0.6)
    if heavy:
        s.poly([(56, 22), (60, 10), (68, 10), (72, 22)], "#ffe34d", stroke=O, sw=3)
    return s


def lift(part):
    s = SVG(128, 64)
    teal = "#4fc4c0"
    if part == "single":
        s.rect(6, 6, 116, 42, s.linear([(0, lighten(teal, 0.35)), (1, darken(teal, 0.1))]), rx=16, stroke=O, sw=SW)
        s.rect(18, 14, 92, 7, "#ffffff", rx=3, opacity=0.6)
    elif part == "mid":
        s.rect(-8, 6, 144, 42, s.linear([(0, lighten(teal, 0.35)), (1, darken(teal, 0.1))]), stroke=O, sw=SW)
        s.rect(-2, 14, 132, 7, "#ffffff", opacity=0.6)
        s.line(64, 26, 64, 46, darken(teal, 0.3), 4)
    else:
        x = 6 if part == "left" else -20
        s.rect(x, 6, 142, 42, s.linear([(0, lighten(teal, 0.35)), (1, darken(teal, 0.1))]), rx=16, stroke=O, sw=SW)
        s.rect(18 if part == "left" else -2, 14, 112, 7, "#ffffff", rx=3, opacity=0.6)
        cx = 26 if part == "left" else 102
        s.circle(cx, 32, 6, GOLD, stroke=O, sw=3)
    return s


def lever():
    s = SVG(120, 124)
    ground_shadow(s, 60, 118, 40, 5)
    s.path("M22 118 Q22 86 60 86 Q98 86 98 118 Z", fill=s.linear([(0, "#b7bfdc"), (1, "#8a93b0")]), stroke=O, sw=SW)
    s.line(60, 96, 34, 34, O, 16)
    s.line(60, 96, 34, 34, "#e2e7fa", 7)
    s.circle(32, 28, 16, s.radial([(0, "#ff9a8a"), (1, "#e0452e")], 0.35, 0.3, 0.8), stroke=O, sw=SW)
    s.circle(27, 22, 4.5, "#ffffff", opacity=0.85)
    return s


def reset_bell():
    s = SVG(120, 130)
    ground_shadow(s, 60, 124, 36, 5)
    wood_rect(s, 52, 70, 16, 56, 5)
    s.circle(60, 46, 38, s.radial([(0, "#d9f1ff"), (1, "#58b8f5")], 0.36, 0.3, 0.85), stroke=O, sw=SW)
    s.path("M40 46 A20 20 0 1 1 60 66", stroke="#ffffff", sw=8)
    s.poly([(60, 54), (60, 78), (44, 66)], "#ffffff")
    return s


def crate(tough=False):
    s = SVG(128, 128)
    base = "#9aa3bd" if tough else WOOD
    s.rect(6, 6, 116, 116, s.linear([(0, lighten(base, 0.2)), (1, darken(base, 0.1))]), rx=12, stroke=O, sw=SW)
    s.rect(18, 18, 92, 92, darken(base, 0.08), rx=6, stroke=darken(base, 0.35), sw=4)
    s.line(22, 22, 106, 106, darken(base, 0.35), 12)
    s.line(22, 22, 106, 106, lighten(base, 0.1), 6)
    s.line(106, 22, 22, 106, darken(base, 0.35), 12)
    s.line(106, 22, 22, 106, lighten(base, 0.1), 6)
    for (x, y) in ((16, 16), (112, 16), (16, 112), (112, 112)):
        s.circle(x, y, 5, "#6e7794" if tough else WOOD_D, stroke=O, sw=2.5)
    if tough:
        s.rect(6, 54, 116, 20, "#6e7794", stroke=O, sw=4)
    return s


def wax():
    s = SVG(128, 128)
    d = "M8 22 Q8 6 24 6 H104 Q120 6 120 22 V124 H8 Z"
    s.path(d, fill=s.linear([(0, "#fff3b8"), (1, "#f2c94c")]), stroke=O, sw=SW)
    s.path("M8 34 Q20 52 30 34 Q40 60 54 34 Q66 48 76 34 Q88 64 100 34 Q110 46 120 34 V22 Q120 6 104 6 H24 Q8 6 8 22 Z", fill="#fffbe0", stroke=O, sw=4)
    s.ellipse(40, 20, 16, 5, "#ffffff", opacity=0.8)
    return s


def iceblock():
    s = SVG(128, 128)
    s.rect(6, 6, 116, 116, s.linear([(0, "#e8fbff"), (1, "#8fd6ee")], 0, 0, 1, 1), rx=16, stroke="#35507a", sw=SW)
    s.poly([(24, 84), (60, 24), (76, 24), (40, 84)], "#ffffff", opacity=0.6)
    s.poly([(66, 100), (88, 62), (98, 62), (76, 100)], "#ffffff", opacity=0.45)
    s.path("M22 30 q4 -10 14 -10", stroke="#ffffff", sw=6)
    return s


def brazier():
    s = SVG(128, 112)
    ground_shadow(s, 64, 106, 50, 6)
    s.line(40, 70, 28, 106, O, 14)
    s.line(40, 70, 28, 106, "#8a93b0", 6)
    s.line(88, 70, 100, 106, O, 14)
    s.line(88, 70, 100, 106, "#8a93b0", 6)
    s.path("M10 36 H118 C118 64 96 78 64 78 C32 78 10 64 10 36 Z", fill=s.linear([(0, "#b7bfdc"), (1, "#6e7794")]), stroke=O, sw=SW)
    s.ellipse(64, 36, 54, 10, "#4a4660", stroke=O, sw=SW)
    for (x, c) in ((44, "#7a4a4a"), (64, "#8a5a4a"), (84, "#7a4a4a")):
        s.circle(x, 36, 8, c)
    return s


def flame():
    s = SVG(96, 124)
    outer = "M48 6 C60 30 86 46 84 82 C82 108 66 120 48 120 C30 120 14 108 12 82 C10 58 30 50 34 30 C40 40 44 40 48 6 Z"
    s.path(outer, fill=s.linear([(0, "#ffb347"), (1, "#f0452e")]), stroke=O, sw=SW)
    inner = "M48 50 C56 62 68 72 66 92 C64 106 56 112 48 112 C40 112 32 106 30 92 C28 78 40 70 48 50 Z"
    s.path(inner, fill=s.linear([(0, "#fff7b0"), (1, "#ffd84a")]))
    return s


def pinwheel():
    s = SVG(160, 160)
    cols = ["#f0452e", "#ffcf3f", "#58b8f5", "#6fc96a"]
    for i in range(4):
        a = math.radians(i * 90)
        ca, sa = math.cos(a), math.sin(a)
        def rot(x, y):
            return (80 + x * ca - y * sa, 80 + x * sa + y * ca)
        pts = [rot(0, 0), rot(66, -6), rot(40, -44)]
        s.path(rounded_poly(pts, 8), fill=cols[i], stroke=O, sw=SW)
        p2 = [rot(0, 0), rot(40, -44), rot(4, -30)]
        s.path(rounded_poly(p2, 4), fill=darken(cols[i], 0.18), stroke=O, sw=4)
    s.circle(80, 80, 11, "#fffaf0", stroke=O, sw=SW)
    return s


def pinwheel_post():
    s = SVG(48, 200)
    ground_shadow(s, 24, 194, 20, 4)
    wood_rect(s, 16, 4, 16, 192, 6)
    return s


def bush(full=True):
    s = SVG(170, 140)
    ground_shadow(s, 85, 132, 70, 7)
    pts = [(10, 128), (8, 86), (34, 54), (62, 60), (84, 22), (112, 54), (140, 50), (164, 90), (160, 128)]
    s.path(smooth_closed(pts, 0.7), fill=s.radial([(0, "#a5e36f"), (0.6, "#6fc96a"), (1, "#3f9a52")], 0.4, 0.25, 0.85), stroke=O, sw=SW)
    s.path("M36 84 q10 -16 26 -12 M100 62 q14 -8 24 4", stroke="#c9f29a", sw=6)
    if full:
        for (x, y) in ((48, 96), (86, 70), (120, 98), (76, 110), (134, 74)):
            s.circle(x, y, 10, s.radial([(0, "#ff9a8a"), (1, "#e0452e")], 0.35, 0.3, 0.8), stroke=O, sw=3.5)
            s.circle(x - 3, y - 3, 2.6, "#ffffff", opacity=0.9)
    return s


def bounce():
    s = SVG(140, 100)
    ground_shadow(s, 70, 94, 44, 5)
    s.path("M50 54 H90 L96 96 H44 Z", fill=s.linear([(0, "#fffaf0"), (1, "#ecd9c0")]), stroke=O, sw=SW)
    cap = "M8 58 C8 22 36 6 70 6 C104 6 132 22 132 58 C132 68 8 68 8 58 Z"
    s.path(cap, fill=s.radial([(0, "#ff9a8a"), (0.6, "#f0452e"), (1, "#c22a24")], 0.4, 0.2, 0.9), stroke=O, sw=SW)
    for (x, y, r) in ((40, 34, 11), (76, 24, 9), (104, 42, 10), (66, 48, 6)):
        s.circle(x, y, r, "#fffaf0", opacity=0.95)
    return s


# -------------------------------------------------------------------- fx --

def bubble_fx():
    s = SVG(200, 200)
    g = s.radial([(0, "#ffffff", 0.05), (0.7, "#bfe4ff", 0.22), (1, "#8ec9ff", 0.7)], 0.5, 0.5, 0.5)
    s.circle(100, 100, 92, g, stroke="#ffffff", sw=5, opacity=0.95)
    s.path("M40 86 A62 62 0 0 1 84 40", stroke="#ffffff", sw=10, opacity=0.85)
    s.circle(142, 150, 9, "#ffffff", opacity=0.6)
    s.circle(100, 100, 92, "none", stroke="#c9b6ff", sw=2.5, opacity=0.8)
    return s


def cloud_fx():
    s = SVG(256, 96)
    pts = [(14, 70), (20, 44), (52, 36), (72, 14), (112, 12), (136, 30), (176, 20), (206, 36), (240, 48), (244, 72), (128, 86)]
    s.path(smooth_closed(pts, 0.8), fill=s.linear([(0, "#ffffff"), (1, "#f6dcec")]), stroke=O, sw=SW)
    s.path("M56 44 q16 -18 40 -14", stroke="#ffffff", sw=8)
    return s


# --------------------------------------------------------------------- ui --

def ui_honk():
    s = SVG(72, 72)
    s.path("M10 22 Q34 12 42 36 Q34 60 10 50 Q18 36 10 22 Z", fill=s.linear([(0, "#ffcf3f"), (1, "#ff9a1f")]), stroke=O, sw=4.5)
    s.path("M50 22 q8 14 0 28", stroke=O, sw=5)
    s.path("M58 14 q14 22 0 44", stroke=O, sw=5)
    return s


def ui_talk():
    s = SVG(84, 72)
    s.path("M10 8 H74 Q80 8 80 16 V44 Q80 52 72 52 H40 L26 66 L28 52 H12 Q4 52 4 44 V16 Q4 8 10 8 Z", fill="#fffaf0", stroke=O, sw=4.5)
    for x in (26, 42, 58):
        s.circle(x, 30, 5, O)
    return s


PROPS = {
    "props/bowl": bowl, "props/station": station, "props/station_flag": station_flag,
    "props/exit": exit_bell, "props/sign": sign, "props/thorns": thorns,
    "props/chime": chime, "props/bell": bell, "props/gate": gate,
    "props/plate": lambda: plate(False), "props/plate_heavy": lambda: plate(True),
    "props/lift_left": lambda: lift("left"), "props/lift_mid": lambda: lift("mid"),
    "props/lift_right": lambda: lift("right"), "props/lift_single": lambda: lift("single"),
    "props/lever": lever, "props/reset": reset_bell,
    "props/crate": lambda: crate(False), "props/crate_tough": lambda: crate(True),
    "props/wax": wax, "props/iceblock": iceblock, "props/brazier": brazier, "props/flame": flame,
    "props/pinwheel": pinwheel, "props/pinwheel_post": pinwheel_post,
    "props/bush_full": lambda: bush(True), "props/bush_empty": lambda: bush(False),
    "props/bounce": bounce,
    "items/crumb": crumb, "items/scrap": scrap, "items/pin": pin, "items/dish": dish, "items/feather": feather,
    "fx/bubble": bubble_fx, "fx/cloud": cloud_fx,
    "ui/honk": ui_honk, "ui/talk": ui_talk,
}


def make_all(assets):
    out = []
    for name, fn in PROPS.items():
        path = os.path.join(assets, "sprites", name + ".svg")
        fn().save(path)
        out.append(path)
    return out
