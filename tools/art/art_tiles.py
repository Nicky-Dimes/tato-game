"""Terrain tile atlases, one per world theme.

Atlas grid: 64 px sub-tiles (authored at 2x; one game cell = 2x2 sub-tiles).
Layout (columns x rows), per material block of 5 rows:
    rows base+0..3, cols 0..3 : edge pieces by kind (0 outer corner, 1 top/bottom
                                 edge, 2 side edge, 3 inner corner) x quadrant (TL TR BL BR)
    row  base+4,    cols 0..3 : interior pieces
    rows base+0..1, cols 4..5 : slope rising right ('/')   (2x2 sub-tiles)
    rows base+0..1, cols 6..7 : slope rising left  ('\\')
    row  base+2,    cols 4..6 : one-way platform left cap / middle / right cap (ground block only)
Materials: ground base=0, struct base=5, ice base=10.
"""
import os
from svgkit import SVG, OUTLINE, mix, darken, lighten, f

S = 64
COLS = 8
ROWS = 15
G = 24          # cap thickness
W = 6           # outline weight
R = 26          # outer corner radius

ICE = {"body": "#a9e4f5", "speck": "#8fd2ea", "under": "#79bfdc", "cap": "#f1fdff", "cap_light": "#ffffff", "cap_shadow": "#8fd2ea", "line": "#35507a", "style": "ice"}

# Colours follow the "TATO World" level-asset board: brown brick earth with a
# bright grass cap, pink frosting on cake, snow on blue ice, castle stone.
THEMES = {
    "grassland": {
        "ground": {"body": "#b9793f", "speck": "#9c602c", "under": "#8a5326", "cap": "#7fd13b", "cap_light": "#b6f06a", "cap_shadow": "#7a4a22", "line": "#4a2b45", "style": "bricks"},
        "struct": {"body": "#a79bc4", "speck": "#8c80ad", "under": "#766a98", "cap": "#c9bfe0", "cap_light": "#e8e2f5", "cap_shadow": "#7d7199", "line": "#3b2850", "style": "bricks"},
        "ice": ICE,
        "plank": {"body": "#e8b06e", "light": "#ffd9a0", "dark": "#b9803f", "cloth": "#f0452e"},
    },
    "orchard": {
        "ground": {"body": "#b06f3a", "speck": "#93582a", "under": "#804a22", "cap": "#63c148", "cap_light": "#a0e670", "cap_shadow": "#73431f", "line": "#4a2b45", "style": "bricks"},
        "struct": {"body": "#d39a58", "speck": "#b97f3f", "under": "#9c6730", "cap": "#f0c58a", "cap_light": "#ffe2b5", "cap_shadow": "#a8733a", "line": "#4a2b45", "style": "planks"},
        "ice": ICE,
        "plank": {"body": "#d9a25c", "light": "#f6cf8c", "dark": "#a9722f", "cloth": "#e0392e"},
    },
    "candy": {
        "ground": {"body": "#e9b877", "speck": "#d39d58", "under": "#bd8646", "cap": "#ff8fc4", "cap_light": "#ffd1e6", "cap_shadow": "#c98a4c", "line": "#5a2848", "style": "soil"},
        "struct": {"body": "#f0b45a", "speck": "#d6933a", "under": "#bb7a2a", "cap": "#ffd98a", "cap_light": "#fff0c4", "cap_shadow": "#c98a3a", "line": "#5a2848", "style": "bricks"},
        "ice": ICE,
        "plank": {"body": "#ff9ccb", "light": "#ffd6ea", "dark": "#d9639d", "cloth": "#ffffff"},
    },
    "icy": {
        "ground": {"body": "#7cc7ee", "speck": "#62b2de", "under": "#4f9fce", "cap": "#ffffff", "cap_light": "#ffffff", "cap_shadow": "#62b2de", "line": "#2c4a7a", "style": "ice"},
        "struct": {"body": "#cfe9f7", "speck": "#b2d6ea", "under": "#97c2da", "cap": "#ffffff", "cap_light": "#ffffff", "cap_shadow": "#a9cfe4", "line": "#2c4a7a", "style": "bricks"},
        "ice": ICE,
        "plank": {"body": "#bfe9fb", "light": "#ffffff", "dark": "#7fbfe0", "cloth": "#59b6f0"},
    },
    "windy": {
        "ground": {"body": "#bd8046", "speck": "#a06731", "under": "#8c5829", "cap": "#8bd94a", "cap_light": "#c2f27e", "cap_shadow": "#7d4f25", "line": "#4a2b45", "style": "bricks"},
        "struct": {"body": "#a79bc4", "speck": "#8c80ad", "under": "#766a98", "cap": "#c9bfe0", "cap_light": "#e8e2f5", "cap_shadow": "#7d7199", "line": "#3b2850", "style": "bricks"},
        "ice": ICE,
        "plank": {"body": "#e3ab63", "light": "#ffd596", "dark": "#b07a38", "cloth": "#8bd94a"},
    },
    "castle": {
        "ground": {"body": "#9a8fb8", "speck": "#8176a1", "under": "#6b608c", "cap": "#c9bfe0", "cap_light": "#ece6f8", "cap_shadow": "#75698f", "line": "#33244a", "style": "bricks"},
        "struct": {"body": "#d9ab4c", "speck": "#bf8f34", "under": "#a37727", "cap": "#f6d98a", "cap_light": "#fff3c4", "cap_shadow": "#b08530", "line": "#402040", "style": "plates"},
        "ice": ICE,
        "plank": {"body": "#d93a4a", "light": "#ff7a86", "dark": "#a32232", "cloth": "#ffd84a"},
    },
    "nest": {
        "ground": {"body": "#c58d5e", "speck": "#b07a4d", "under": "#9a6642", "cap": "#9bd96a", "cap_light": "#c9f29a", "cap_shadow": "#96693f", "line": "#4a2b45", "style": "soil"},
        "struct": {"body": "#f0c98e", "speck": "#deb174", "under": "#c2935a", "cap": "#fde4b8", "cap_light": "#fff5dc", "cap_shadow": "#c99b60", "line": "#4a2b45", "style": "planks"},
        "ice": ICE,
        "plank": {"body": "#e8b06e", "light": "#ffd9a0", "dark": "#b9803f", "cloth": "#f5a2a8"},
    },
}


def interior(svg, pal, q, variant):
    """Material texture for one sub-tile (local coords 0..S)."""
    style = pal["style"]
    svg.rect(-1, -1, S + 2, S + 2, pal["body"])
    sp = pal["speck"]
    if style in ("soil", "stone"):
        dots = [
            [],
            [(18, 22, 7, 5), (46, 44, 5, 4)],
            [(40, 16, 6, 4), (14, 46, 4, 3), (50, 52, 3, 3)],
            [(28, 34, 8, 5)],
        ][variant % 4]
        for (x, y, rx, ry) in dots:
            svg.ellipse(x, y, rx, ry, sp, opacity=0.75)
            svg.ellipse(x - 1, y - 1.5, rx * 0.6, ry * 0.45, lighten(pal["body"], 0.18), opacity=0.5)
    elif style == "planks":
        # horizontal boards with staggered joints
        svg.rect(-1, S - 4, S + 2, 4, sp)
        svg.rect(-1, 0, S + 2, 3, lighten(pal["body"], 0.16), opacity=0.7)
        jx = [20, 46, 44, 18][q]
        svg.rect(jx, 0, 4, S - 4, sp)
        svg.circle(jx - 7, 14, 2.5, darken(sp, 0.2))
    elif style == "bricks":
        svg.rect(-1, S - 4, S + 2, 4, sp)
        svg.rect(-1, 28, S + 2, 4, sp)
        if q in (0, 3):
            svg.rect(30, 0, 4, 28, sp)
            svg.rect(-2, 32, 4, 28, sp)
        else:
            svg.rect(-2, 0, 4, 28, sp)
            svg.rect(30, 32, 4, 28, sp)
    elif style == "stripes":
        for i in range(-2, 4):
            x = i * 32 + (0 if q % 2 == 0 else 0)
            svg.poly([(x, S + 1), (x + 16, S + 1), (x + 16 + S, -1), (x + S, -1)], lighten(pal["body"], 0.3), opacity=0.55)
    elif style == "plates":
        svg.rect(-1, S - 3, S + 2, 3, sp)
        if q in (0, 2):
            svg.rect(-1.5, -1, 3, S + 2, sp)
        if q in (0, 1):
            svg.circle(12 if q == 0 else S - 12, 12, 4, darken(pal["body"], 0.18))
            svg.circle((12 if q == 0 else S - 12) - 1, 11, 2, lighten(pal["body"], 0.35))
        else:
            svg.circle(12 if q == 2 else S - 12, S - 14, 4, darken(pal["body"], 0.18))
            svg.circle((12 if q == 2 else S - 12) - 1, S - 15, 2, lighten(pal["body"], 0.35))
    elif style == "ice":
        if variant % 2 == 0:
            svg.poly([(10, 40), (26, 12), (32, 12), (16, 40)], "#ffffff", opacity=0.45)
            svg.poly([(30, 46), (40, 28), (44, 28), (34, 46)], "#ffffff", opacity=0.3)
        else:
            svg.poly([(34, 50), (50, 22), (55, 22), (39, 50)], "#ffffff", opacity=0.4)


def cap_path(corner):
    """Top cap band in canonical (exposed-left) orientation."""
    if corner:
        return ("M%d 0 L%d 0 Q0 0 0 %d L0 %d Q2 %d 12 %d Q22 %d 32 %d Q48 %d %d %d Z"
                % (S + 1, R, R, R + 20, G + 14, G + 6, G, G, G + 9, S + 1, G))
    return "M-1 0 L%d 0 L%d %d Q48 %d 32 %d Q16 %d -1 %d Z" % (S + 1, S + 1, G, G + 9, G, G + 9, G)


def edge_piece(svg, pal, kind, top, material):
    """Draws edge decoration in canonical orientation: exposed side is LEFT.
    kind: 0 outer corner, 1 horizontal edge (top or bottom exposed), 2 side edge, 3 inner corner."""
    line = pal["line"]
    flat_cap = pal["style"] in ("planks", "bricks", "stripes", "plates")
    if kind in (0, 1):
        if top:
            if flat_cap:
                d = ("M%d 0 L%d 0 Q0 0 0 %d L0 %d L%d %d Z" % (S + 1, R, R, G - 4, S + 1, G - 4)) if kind == 0 else "M-1 0 H%d V%d H-1 Z" % (S + 1, G - 4)
                svg.path(d, pal["cap"])
                svg.rect(-1, G - 4, S + 2, 4, pal["cap_shadow"])
                svg.rect(-1 if kind == 1 else R * 0.6, W, S + 2, 5, pal["cap_light"], opacity=0.9)
            else:
                # soft shadow under the cap, then the cap, then a light strip
                svg.path(cap_path(kind == 0), pal["cap_shadow"], extra=' transform="translate(0 6)"')
                svg.path(cap_path(kind == 0), pal["cap"])
                if kind == 0:
                    svg.path("M%d %d L%d %d Q%d %d %d %d" % (S + 1, W + 4, R + 4, W + 4, W + 5, W + 5, W + 4, R + 6), stroke=pal["cap_light"], sw=5, opacity=0.95)
                else:
                    svg.rect(-1, W + 1.5, S + 2, 5, pal["cap_light"], opacity=0.95)
        else:
            # underside band (canonical for bottom: drawn at the bottom of the tile)
            if kind == 0:
                svg.path("M%d %d L%d %d Q0 %d 0 %d L0 %d Q0 %d %d %d L%d %d Z" % (S + 1, S, R, S, S, S - R, S - R - 8, S - 14, R, S - 14, S + 1, S - 14), pal["under"])
            else:
                svg.rect(-1, S - 14, S + 2, 14, pal["under"])
    if kind in (0, 2):
        # side rim tint
        svg.rect(W, -1 if kind == 2 else (R if top else -1), 5, S + 2 if kind == 2 else S - R + 1, "#ffffff", opacity=0.16)
    # outline
    if kind == 0:
        if top:
            svg.path("M%d %s L%d %s Q%s %s %s %d L%s %d" % (S + 1, f(W / 2), R, f(W / 2), f(W / 2), f(W / 2), f(W / 2), R, f(W / 2), S + 1), stroke=line, sw=W, cap="butt")
        else:
            svg.path("M%d %s L%d %s Q%s %s %s %d L%s %d" % (S + 1, f(S - W / 2), R, f(S - W / 2), f(W / 2), f(S - W / 2), f(W / 2), S - R, f(W / 2), -1), stroke=line, sw=W, cap="butt")
    elif kind == 1:
        y = W / 2 if top else S - W / 2
        svg.path("M-1 %s H%d" % (f(y), S + 1), stroke=line, sw=W, cap="butt")
    elif kind == 2:
        svg.path("M%s -1 V%d" % (f(W / 2), S + 1), stroke=line, sw=W, cap="butt")
    elif kind == 3:
        cy = 0 if top else S
        if top:
            if not flat_cap:
                svg.circle(0, 0, G + 6, pal["cap_shadow"])
                svg.circle(0, 0, G, pal["cap"])
            else:
                svg.rect(0, 0, G - 4, G - 4, pal["cap"])
                svg.rect(0, G - 4, G, 4, pal["cap_shadow"])
        else:
            svg.circle(0, S, 14, pal["under"])
        svg.rect(-1, cy - W if not top else -1, W + 1, W + 1, line)


def body_clip_path(kind, top):
    """Body silhouette in canonical orientation (only the outer corner is not a full square)."""
    if kind != 0:
        return None
    if top:
        return "M%d -1 L%d 0 Q0 0 0 %d L0 %d L%d %d Z" % (S + 1, R, R, S + 1, S + 1, S + 1)
    return "M%d %d L%d %d Q0 %d 0 %d L0 -1 L%d -1 Z" % (S + 1, S + 1, R, S, S, S - R, S + 1)


def draw_subtile(svg, col, row, pal, material, q, kind, variant=0):
    ox, oy = col * S, row * S
    left = q in (0, 2)
    top = q in (0, 1)
    clip = svg.clip_rect(ox, oy, S, S)
    svg.group_open(clip=clip)
    if left:
        svg.group_open(transform="translate(%d %d)" % (ox, oy))
    else:
        svg.group_open(transform="translate(%d %d) scale(-1 1)" % (ox + S, oy))
    body = body_clip_path(kind, top) if kind == 0 else None
    if body:
        inner = svg.clip_path(body)
        svg.group_open(clip=inner)
    interior(svg, pal, q if left else (q - 1), variant)
    if kind < 4:
        edge_piece(svg, pal, kind, top, material)
    if body:
        svg.group_close()
        # the outline must not be clipped by the body shape: redraw it on top
        line = pal["line"]
        if top:
            svg.path("M%d %s L%d %s Q%s %s %s %d L%s %d" % (S + 1, f(W / 2), R, f(W / 2), f(W / 2), f(W / 2), f(W / 2), R, f(W / 2), S + 1), stroke=line, sw=W, cap="butt")
        else:
            svg.path("M%d %s L%d %s Q%s %s %s %d L%s %d" % (S + 1, f(S - W / 2), R, f(S - W / 2), f(W / 2), f(S - W / 2), f(W / 2), S - R, f(W / 2), -1), stroke=line, sw=W, cap="butt")
    svg.group_close()
    svg.group_close()


def draw_slope(svg, col, row, pal, rising_right):
    """2x2 sub-tile slope. Canonical: rises to the right ('/')."""
    ox, oy = col * S, row * S
    T = S * 2
    clip = svg.clip_rect(ox, oy, T, T)
    svg.group_open(clip=clip)
    if rising_right:
        svg.group_open(transform="translate(%d %d)" % (ox, oy))
    else:
        svg.group_open(transform="translate(%d %d) scale(-1 1)" % (ox + T, oy))
    tri = "M0 %d L%d 0 L%d %d Z" % (T, T, T, T)
    inner = svg.clip_path("M-2 %d L%d -2 L%d %d Z" % (T + 2, T + 2, T + 2, T + 2))
    svg.group_open(clip=inner)
    svg.rect(0, 0, T, T, pal["body"])
    flat_cap = pal["style"] in ("planks", "bricks", "stripes", "plates")
    k = 1.42
    cap_h = (G - 4 if flat_cap else G + 3) * k
    svg.poly([(-2, T + 2 + cap_h + 8), (T + 2, -2 + cap_h + 8), (T + 2, -2), (-2, T + 2)], pal["cap_shadow"])
    svg.poly([(-2, T + 2 + cap_h), (T + 2, -2 + cap_h), (T + 2, -2), (-2, T + 2)], pal["cap"])
    off = (W + 4) * k
    svg.path("M-2 %s L%d %s" % (f(T + 2 + off), T + 2, f(-2 + off)), stroke=pal["cap_light"], sw=5, opacity=0.95, cap="butt")
    svg.group_close()
    o = W / 2 * k
    svg.path("M-2 %s L%d %s" % (f(T + 2 + o), T + 2, f(-2 + o)), stroke=pal["line"], sw=W, cap="butt")
    svg.group_close()
    svg.group_close()


def draw_plank(svg, col, row, pp, line, part):
    """One-way platform piece: 0 left cap, 1 middle, 2 right cap (drawn in the top 30 px)."""
    ox, oy = col * S, row * S
    clip = svg.clip_rect(ox, oy, S, S)
    svg.group_open(clip=clip)
    if part == 2:
        svg.group_open(transform="translate(%d %d) scale(-1 1)" % (ox + S, oy))
    else:
        svg.group_open(transform="translate(%d %d)" % (ox, oy))
    H = 26
    if part == 1:
        svg.rect(-4, W / 2, S + 8, H, pp["body"], stroke=line, sw=W)
        svg.rect(-1, W + 1, S + 2, 5, pp["light"])
        svg.rect(-1, H - 5, S + 2, 5, pp["dark"])
        svg.rect(30, W, 3, H - W, pp["dark"], opacity=0.7)
    else:
        svg.rect(W / 2, W / 2, S + 10, H, pp["body"], rx=10, stroke=line, sw=W)
        svg.rect(W + 6, W + 1, S, 5, pp["light"])
        svg.rect(W + 4, H - 5, S, 5, pp["dark"])
        # little bracket peg
        svg.path("M20 %d L20 %d Q20 %d 30 %d L%d %d" % (H + 1, H + 12, H + 20, H + 20, S + 2, H + 20), stroke=line, sw=W, opacity=0.0)
        svg.circle(18, H / 2 + 2, 4, pp["dark"])
        svg.circle(17, H / 2 + 1, 2, pp["light"])
    svg.group_close()
    svg.group_close()


def make_atlas(theme, out_dir):
    pals = THEMES[theme]
    svg = SVG(COLS * S, ROWS * S)
    for mi, material in enumerate(("ground", "struct", "ice")):
        pal = pals[material]
        base = mi * 5
        for kind in range(4):
            for q in range(4):
                draw_subtile(svg, q, base + kind, pal, material, q, kind, variant=q)
        for v in range(4):
            draw_subtile(svg, v, base + 4, pal, material, v if pal["style"] in ("planks", "bricks", "plates", "stripes") else 0, 4, variant=v)
        draw_slope(svg, 4, base, pal, True)
        draw_slope(svg, 6, base, pal, False)
    line = pals["ground"]["line"]
    for part in range(3):
        draw_plank(svg, 4 + part, 2, pals["plank"], line, part)
    path = os.path.join(out_dir, "tiles_%s.svg" % theme)
    svg.save(path)
    return path


def make_all(out_dir):
    return [make_atlas(t, out_dir) for t in THEMES]
