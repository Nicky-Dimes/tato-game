"""Creatures and friends: the mischievous food sprites and the valley folk.
Same recipe as everything else: round bodies, soft shading, plum outline,
glossy eyes, blush. Standing figures have their feet on the bottom edge."""
import math
import os
from svgkit import (SVG, OUTLINE, OUTLINE_W, mix, darken, lighten, f, blob_path, soft_body,
                    gloss, star_path, smooth_closed, rounded_poly, eye, blush, smile, ground_shadow)

O = OUTLINE
SW = OUTLINE_W


# ---------------------------------------------------------------- enemies --

def crumb_mite():
    s = SVG(104, 92)
    ground_shadow(s, 52, 86, 34, 5)
    for x in (30, 46, 60, 76):
        s.line(x, 70, x - 3 if x < 52 else x + 3, 86, O, 7)
    body = rounded_poly([(14, 50), (26, 22), (52, 12), (80, 22), (92, 50), (78, 74), (28, 74)], 14)
    soft_body(s, body, "#e8b05e")
    s.circle(34, 34, 5, "#c98a3a")
    s.circle(72, 60, 4, "#c98a3a")
    s.circle(60, 24, 3.5, "#fff0c4")
    eye(s, 40, 50, 9, iris="#8a5a2a")
    eye(s, 64, 50, 9, iris="#8a5a2a")
    blush(s, 28, 60, 8, 5)
    blush(s, 76, 60, 8, 5)
    s.path("M47 63 q5 5 10 0", stroke=O, sw=3)
    return s


# ------------------------------------------------------------------- npcs --

def mimi():
    """Mimi: elderly field-mouse librarian. Shawl, round glasses, a book."""
    s = SVG(170, 190)
    ground_shadow(s, 85, 184, 56, 7)
    # tail
    s.path("M118 160 C150 164 160 140 148 122", stroke=O, sw=11)
    s.path("M118 160 C150 164 160 140 148 122", stroke="#f5b8b0", sw=5)
    # ears
    for cx in (48, 122):
        s.circle(cx, 40, 26, s.radial([(0, "#e9d2c0"), (1, "#c9a88e")], 0.4, 0.3, 0.85), stroke=O, sw=SW)
        s.circle(cx, 42, 15, "#f5b8b0")
    # body + shawl
    body = blob_path(85, 132, 50, 50, 0.02, 10)
    soft_body(s, body, "#d9bfa6")
    s.path("M38 122 Q85 96 132 122 L126 160 Q85 176 44 160 Z", fill=s.linear([(0, "#b99be0"), (1, "#8a6cc4")]), stroke=O, sw=SW)
    s.path("M44 138 Q85 156 126 138", stroke="#d9c8f2", sw=4)
    # head
    head = blob_path(85, 76, 48, 42, 0.02, 10)
    soft_body(s, head, "#e6d0bb")
    s.ellipse(85, 92, 20, 14, "#fff3e6")
    s.ellipse(85, 86, 6, 4.5, "#f08a9a", stroke=O, sw=3)
    s.path("M79 96 q6 6 12 0", stroke=O, sw=3)
    for sx in (-1, 1):
        s.path("M%d 92 l%d -4 M%d 96 l%d 2" % (85 + sx * 20, sx * 18, 85 + sx * 20, sx * 18), stroke=O, sw=2.5, opacity=0.7)
    eye(s, 66, 72, 8, iris="#6b4a8a")
    eye(s, 104, 72, 8, iris="#6b4a8a")
    for cx in (66, 104):
        s.circle(cx, 72, 14, "none", stroke="#8a6a3a", sw=4)
    s.line(80, 72, 90, 72, "#8a6a3a", 4)
    blush(s, 52, 88, 9, 6)
    blush(s, 118, 88, 9, 6)
    # bun of grey hair
    s.circle(85, 34, 12, "#f1ecf7", stroke=O, sw=4)
    # book
    s.rect(60, 136, 50, 34, "#e0452e", rx=5, stroke=O, sw=SW)
    s.rect(66, 141, 38, 24, "#fffaf0", rx=3)
    s.path(star_path(85, 153, 8, 3.6), fill="#ffcf3f", stroke=O, sw=2.5)
    # feet
    s.ellipse(64, 180, 14, 7, "#f5b8b0", stroke=O, sw=4)
    s.ellipse(106, 180, 14, 7, "#f5b8b0", stroke=O, sw=4)
    return s


CREATURES = {
    "enemies/crumb_mite": crumb_mite,
    "npcs/mimi": mimi,
}


def make_all(assets):
    out = []
    for name, fn in CREATURES.items():
        path = os.path.join(assets, "sprites", name + ".svg")
        fn().save(path)
        out.append(path)
    return out
