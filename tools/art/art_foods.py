"""The twelve magical foods (icons double as the pickups in snack bowls).
Each has its own colour AND its own silhouette so nobody has to rely on
colour alone to tell them apart. 128x128 canvas (shown at 64)."""
import math
import os
from svgkit import SVG, OUTLINE, OUTLINE_W, mix, darken, lighten, f, blob_path, soft_body, gloss, star_path, smooth_closed, rounded_poly

W = 128
O = OUTLINE
SW = OUTLINE_W


def leaf(svg, x, y, w, h, rot, color="#6fc96a"):
    """A leaf from (x, y) pointing along `rot` degrees. Drawn in absolute
    coordinates: the rasteriser drops gradient fills on shapes whose local
    bounding box goes negative, so no transformed groups here."""
    a = math.radians(rot)
    ux, uy = math.cos(a), math.sin(a)
    px, py = -uy, ux
    tip = (x + ux * w, y + uy * w)
    c1 = (x + ux * w / 2 + px * -h, y + uy * w / 2 + py * -h)
    c2 = (x + ux * w / 2 + px * h, y + uy * w / 2 + py * h)
    d = "M%s %s Q%s %s %s %s Q%s %s %s %s Z" % (f(x), f(y), f(c1[0]), f(c1[1]), f(tip[0]), f(tip[1]), f(c2[0]), f(c2[1]), f(x), f(y))
    svg.path(d, fill=svg.linear([(0, lighten(color, 0.25)), (1, darken(color, 0.12))], 0, 0, 1, 1), stroke=O, sw=SW)
    svg.line(x + ux * w * 0.18, y + uy * w * 0.18, x + ux * w * 0.8, y + uy * w * 0.8, darken(color, 0.3), 2.5)


def pepper(svg):
    d = "M44 34 C20 40 14 78 40 102 C58 118 92 112 104 96 C112 86 100 84 92 88 C70 96 58 80 62 58 C64 44 56 32 44 34 Z"
    svg.path(d, fill=svg.linear([(0, "#ff7a5c"), (0.5, "#f0452e"), (1, "#c22a24")], 0, 0, 1, 1), stroke=O, sw=SW)
    svg.path("M36 56 C30 68 34 84 44 92", stroke="#ffffff", sw=6, opacity=0.55)
    svg.path("M40 36 C40 22 54 18 60 10 C66 16 62 28 56 36 Z", fill="#6fc96a", stroke=O, sw=SW)


def bubble(svg):
    for (x, y, r) in ((46, 80, 27), (84, 76, 25), (64, 46, 24)):
        g = svg.radial([(0, "#bfe4ff"), (0.6, "#58b8f5"), (1, "#3a7fd6")], 0.35, 0.3, 0.8)
        svg.circle(x, y, r, g, stroke=O, sw=SW)
        svg.circle(x - r * 0.32, y - r * 0.36, r * 0.24, "#ffffff", opacity=0.9)
        svg.path("M%s %s l5 -4 l5 4 l-5 4 Z" % (f(x - 5 + r * 0.25), f(y + r * 0.1)), fill=darken("#3a7fd6", 0.2), opacity=0.55)
    leaf(svg, 70, 26, 34, 12, -28)


def honey(svg):
    def hexa(cx, cy, r):
        return [(cx + r * math.cos(math.radians(60 * i)), cy + r * math.sin(math.radians(60 * i))) for i in range(6)]
    cells = [(44, 50), (84, 50), (64, 84), (24, 84), (104, 84)]
    for (cx, cy) in cells[:3]:
        svg.poly(hexa(cx, cy, 25), svg.linear([(0, "#ffd866"), (1, "#f5a623")]), stroke=O, sw=SW)
        svg.poly(hexa(cx, cy, 13), "#ffbe3d", stroke="#c9801a", sw=3)
        svg.circle(cx - 6, cy - 6, 4, "#ffffff", opacity=0.8)
    svg.path("M52 100 C52 116 62 118 62 108 C62 118 76 120 76 104 Z", fill="#ffbe3d", stroke=O, sw=SW)


def melon(svg):
    svg.path("M14 44 A52 52 0 0 0 114 44 Z", fill="#3fae4a", stroke=O, sw=SW)
    svg.path("M22 44 A44 44 0 0 0 106 44 Z", fill="#e9f7d9")
    svg.path("M28 44 A38 38 0 0 0 100 44 Z", fill=svg.linear([(0, "#ff7f8c"), (1, "#f25a6e")]))
    svg.path("M14 44 H114", stroke=O, sw=SW)
    for (x, y) in ((48, 58), (64, 68), (80, 58), (64, 50)):
        svg.ellipse(x, y, 3.2, 5, "#3a1f4d")
    svg.path("M36 50 Q64 54 92 50", stroke="#ffffff", sw=4, opacity=0.5)


def frost(svg):
    g = svg.radial([(0, "#e8fbff"), (0.6, "#7fe0ef"), (1, "#3fb0d0")], 0.35, 0.3, 0.8)
    svg.circle(64, 76, 34, g, stroke=O, sw=SW)
    svg.poly([(40, 50), (48, 20), (58, 44)], "#e8fbff", stroke=O, sw=SW)
    svg.poly([(56, 44), (66, 12), (76, 44)], "#ffffff", stroke=O, sw=SW)
    svg.poly([(72, 46), (88, 22), (90, 52)], "#e8fbff", stroke=O, sw=SW)
    for a in range(0, 180, 60):
        dx, dy = 15 * math.cos(math.radians(a)), 15 * math.sin(math.radians(a))
        svg.line(64 - dx, 82 - dy, 64 + dx, 82 + dy, "#ffffff", 4.5)
    svg.circle(48, 62, 6, "#ffffff", opacity=0.85)


def popcorn(svg):
    for (x, y, r) in ((40, 42, 17), (64, 30, 19), (88, 42, 17), (52, 50, 15), (76, 52, 15)):
        svg.circle(x, y, r, svg.radial([(0, "#ffffff"), (1, "#ffe9a8")], 0.4, 0.35, 0.8), stroke=O, sw=SW)
    svg.poly([(30, 56), (98, 56), (90, 116), (38, 116)], "#ffffff", stroke=O, sw=SW)
    for i in range(3):
        x0 = 36 + i * 22
        svg.poly([(x0 + 2, 59), (x0 + 12, 59), (x0 + 11.5 - (i - 1) * 1.0, 113.5), (x0 + 4 - (i - 1) * 1.0, 113.5)], "#f0452e")
    svg.rect(28, 54, 72, 9, "#ffd84a", rx=4, stroke=O, sw=4)


def noodle(svg):
    svg.path("M16 66 H112 C112 100 92 114 64 114 C36 114 16 100 16 66 Z", fill=svg.linear([(0, "#ff9a7a"), (1, "#e8743b")]), stroke=O, sw=SW)
    svg.rect(44, 108, 40, 10, "#c95a2a", rx=4, stroke=O, sw=4)
    svg.ellipse(64, 66, 48, 12, "#f9e2a8", stroke=O, sw=SW)
    for i, (x, y) in enumerate(((44, 62), (64, 58), (84, 62))):
        svg.path("M%d %d c-10 -8 10 -18 0 -28 c-8 -8 8 -14 2 -20" % (x, y - 2), stroke=O, sw=9)
        svg.path("M%d %d c-10 -8 10 -18 0 -28 c-8 -8 8 -14 2 -20" % (x, y - 2), stroke="#f2c879", sw=5)
    svg.line(92, 20, 112, 60, O, 8)
    svg.line(92, 20, 112, 60, "#c98f52", 4)
    svg.line(102, 16, 118, 58, O, 8)
    svg.line(102, 16, 118, 58, "#c98f52", 4)


def citrus(svg):
    svg.circle(64, 66, 46, svg.radial([(0, "#ffc45c"), (1, "#ff8a1f")], 0.4, 0.35, 0.8), stroke=O, sw=SW)
    svg.circle(64, 66, 37, "#fff3c4")
    for i in range(8):
        a0 = math.radians(i * 45 + 5)
        a1 = math.radians(i * 45 + 40)
        p0 = (64 + 33 * math.cos(a0), 66 + 33 * math.sin(a0))
        p1 = (64 + 33 * math.cos(a1), 66 + 33 * math.sin(a1))
        svg.path("M64 66 L%s %s A33 33 0 0 1 %s %s Z" % (f(p0[0]), f(p0[1]), f(p1[0]), f(p1[1])), fill="#ffab2e")
    svg.circle(64, 66, 6, "#fff3c4")
    svg.circle(46, 46, 6, "#ffffff", opacity=0.8)
    leaf(svg, 76, 22, 36, 13, -20)


def mint(svg):
    svg.path("M92 20 A40 40 0 1 0 110 76 A31 31 0 1 1 92 20 Z", fill=svg.linear([(0, "#fff7c9"), (1, "#ffe07a")]), stroke=O, sw=SW)
    leaf(svg, 22, 96, 62, 22, -50, "#3ccfb4")
    leaf(svg, 30, 100, 60, 22, -8, "#56dcc0")
    svg.circle(92, 36, 4, "#ffffff", opacity=0.9)


def jam(svg):
    svg.rect(26, 44, 76, 70, svg.linear([(0, "#f25fb0"), (1, "#c22a80")]), rx=16, stroke=O, sw=SW)
    svg.rect(34, 52, 12, 44, "#ffffff", rx=6, opacity=0.45)
    svg.rect(22, 24, 84, 24, "#fff3d6", rx=8, stroke=O, sw=SW)
    svg.path("M22 40 Q32 50 42 40 Q52 50 62 40 Q72 50 82 40 Q92 50 106 40", stroke="#f5a2a8", sw=4)
    svg.path(star_path(68, 82, 19, 8.5), fill="#ffe27a", stroke=O, sw=4)


def truffle(svg):
    svg.path("M20 104 L32 78 H96 L108 104 Z", fill="#fff3d6", stroke=O, sw=SW)
    for x in range(36, 100, 12):
        svg.line(x, 82, x - 4, 102, "#e0c9a0", 3)
    svg.circle(64, 58, 38, svg.radial([(0, "#a47be8"), (0.6, "#7a4fcf"), (1, "#4f2f96")], 0.36, 0.3, 0.8), stroke=O, sw=SW)
    svg.poly([(70, 24), (50, 58), (64, 58), (56, 88), (84, 50), (68, 50), (78, 24)], "#ffe34d", stroke=O, sw=4)
    svg.circle(44, 42, 6, "#ffffff", opacity=0.7)


def pastry(svg):
    svg.path("M14 92 Q14 70 34 68 H94 Q114 70 114 92 Q114 108 64 108 Q14 108 14 92 Z", fill=svg.linear([(0, "#f6c98a"), (1, "#d99a52")]), stroke=O, sw=SW)
    pts = [(24, 66), (30, 48), (46, 50), (54, 34), (72, 34), (80, 48), (98, 46), (104, 66), (64, 76)]
    svg.path(smooth_closed(pts, 0.9), fill="#fffaf0", stroke=O, sw=SW)
    svg.path("M22 44 Q20 20 46 22 Q64 2 84 20 Q110 18 106 44 Q64 60 22 44 Z", fill=svg.linear([(0, "#ffe2a8"), (1, "#f0b566")]), stroke=O, sw=SW)
    svg.ellipse(48, 30, 12, 5, "#ffffff", opacity=0.6, rot=-15)
    for (x, y) in ((40, 84), (64, 90), (88, 84)):
        svg.circle(x, y, 3, "#c98742")


FOODS = {
    "pepper": pepper, "bubble": bubble, "honey": honey, "melon": melon,
    "frost": frost, "popcorn": popcorn, "noodle": noodle, "citrus": citrus,
    "mint": mint, "jam": jam, "truffle": truffle, "pastry": pastry,
}


def make_all(assets):
    out = []
    for name, fn in FOODS.items():
        svg = SVG(W, W)
        fn(svg)
        path = os.path.join(assets, "sprites", "foods", name + ".svg")
        svg.save(path)
        out.append(path)
    return out
