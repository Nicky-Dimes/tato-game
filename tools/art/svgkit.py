"""Shared helpers for the generated vector art (tiles, props, creatures, UI).

Every drawing uses the same recipe so the whole game reads as one style:
soft cel shading (base + one shade + one highlight), a dark plum outline of
constant weight, round friendly shapes, glossy eyes and pink blush.
"""
import math

OUTLINE = "#3a1f4d"      # dark plum line used everywhere
OUTLINE_W = 5             # line weight at 2x authoring scale


def hex_to_rgb(h):
    h = h.lstrip("#")
    return tuple(int(h[i:i + 2], 16) for i in (0, 2, 4))


def rgb_to_hex(rgb):
    return "#%02x%02x%02x" % tuple(max(0, min(255, int(round(c)))) for c in rgb)


def mix(a, b, t):
    ra, rb = hex_to_rgb(a), hex_to_rgb(b)
    return rgb_to_hex(tuple(ra[i] + (rb[i] - ra[i]) * t for i in range(3)))


def darken(c, t=0.2):
    return mix(c, "#2a1238", t)


def lighten(c, t=0.25):
    return mix(c, "#ffffff", t)


def f(v):
    """Compact number formatting."""
    s = "%.2f" % v
    s = s.rstrip("0").rstrip(".")
    return s if s else "0"


class SVG:
    def __init__(self, w, h):
        self.w = w
        self.h = h
        self.defs = []
        self.items = []
        self._n = 0

    def uid(self, prefix="g"):
        self._n += 1
        return "%s%d" % (prefix, self._n)

    def add(self, s):
        self.items.append(s)

    # ---- gradients -------------------------------------------------------
    def linear(self, stops, x1=0, y1=0, x2=0, y2=1, units="objectBoundingBox"):
        gid = self.uid("lg")
        s = '<linearGradient id="%s" x1="%s" y1="%s" x2="%s" y2="%s" gradientUnits="%s">' % (gid, f(x1), f(y1), f(x2), f(y2), units)
        for off, colr, *op in stops:
            o = ' stop-opacity="%s"' % f(op[0]) if op else ""
            s += '<stop offset="%s" stop-color="%s"%s/>' % (f(off), colr, o)
        s += "</linearGradient>"
        self.defs.append(s)
        return "url(#%s)" % gid

    def radial(self, stops, cx=0.5, cy=0.5, r=0.5, units="objectBoundingBox"):
        gid = self.uid("rg")
        s = '<radialGradient id="%s" cx="%s" cy="%s" r="%s" gradientUnits="%s">' % (gid, f(cx), f(cy), f(r), units)
        for off, colr, *op in stops:
            o = ' stop-opacity="%s"' % f(op[0]) if op else ""
            s += '<stop offset="%s" stop-color="%s"%s/>' % (f(off), colr, o)
        s += "</radialGradient>"
        self.defs.append(s)
        return "url(#%s)" % gid

    # ---- primitives ------------------------------------------------------
    def rect(self, x, y, w, h, fill, rx=0, stroke=None, sw=0, opacity=None, extra=""):
        s = '<rect x="%s" y="%s" width="%s" height="%s" fill="%s"' % (f(x), f(y), f(w), f(h), fill)
        if rx:
            s += ' rx="%s"' % f(rx)
        s += self._stroke(stroke, sw) + self._op(opacity) + extra + "/>"
        self.add(s)

    def circle(self, cx, cy, r, fill, stroke=None, sw=0, opacity=None):
        self.add('<circle cx="%s" cy="%s" r="%s" fill="%s"%s%s/>' % (f(cx), f(cy), f(r), fill, self._stroke(stroke, sw), self._op(opacity)))

    def ellipse(self, cx, cy, rx, ry, fill, stroke=None, sw=0, opacity=None, rot=0):
        tr = ' transform="rotate(%s %s %s)"' % (f(rot), f(cx), f(cy)) if rot else ""
        self.add('<ellipse cx="%s" cy="%s" rx="%s" ry="%s" fill="%s"%s%s%s/>' % (f(cx), f(cy), f(rx), f(ry), fill, self._stroke(stroke, sw), self._op(opacity), tr))

    def path(self, d, fill="none", stroke=None, sw=0, opacity=None, cap="round", join="round", extra=""):
        s = '<path d="%s" fill="%s"' % (d, fill)
        s += self._stroke(stroke, sw)
        if stroke:
            s += ' stroke-linecap="%s" stroke-linejoin="%s"' % (cap, join)
        s += self._op(opacity) + extra + "/>"
        self.add(s)

    def poly(self, pts, fill, stroke=None, sw=0, opacity=None):
        d = "M" + " L".join("%s %s" % (f(x), f(y)) for x, y in pts) + " Z"
        self.path(d, fill, stroke, sw, opacity)

    def line(self, x1, y1, x2, y2, stroke, sw, opacity=None):
        self.add('<line x1="%s" y1="%s" x2="%s" y2="%s" stroke="%s" stroke-width="%s" stroke-linecap="round"%s/>' % (f(x1), f(y1), f(x2), f(y2), stroke, f(sw), self._op(opacity)))

    def group_open(self, transform=None, opacity=None, clip=None):
        s = "<g"
        if transform:
            s += ' transform="%s"' % transform
        if opacity is not None:
            s += ' opacity="%s"' % f(opacity)
        if clip:
            s += ' clip-path="url(#%s)"' % clip
        self.add(s + ">")

    def group_close(self):
        self.add("</g>")

    def clip_rect(self, x, y, w, h):
        cid = self.uid("cp")
        self.defs.append('<clipPath id="%s"><rect x="%s" y="%s" width="%s" height="%s"/></clipPath>' % (cid, f(x), f(y), f(w), f(h)))
        return cid

    def clip_path(self, d):
        cid = self.uid("cp")
        self.defs.append('<clipPath id="%s"><path d="%s"/></clipPath>' % (cid, d))
        return cid

    @staticmethod
    def _stroke(stroke, sw):
        if not stroke:
            return ""
        return ' stroke="%s" stroke-width="%s"' % (stroke, f(sw))

    @staticmethod
    def _op(opacity):
        return "" if opacity is None else ' opacity="%s"' % f(opacity)

    def render(self):
        out = '<svg xmlns="http://www.w3.org/2000/svg" width="%d" height="%d" viewBox="0 0 %d %d">' % (self.w, self.h, self.w, self.h)
        if self.defs:
            out += "<defs>" + "".join(self.defs) + "</defs>"
        out += "".join(self.items) + "</svg>\n"
        return out

    def save(self, path):
        import os
        os.makedirs(os.path.dirname(path), exist_ok=True)
        with open(path, "w") as fh:
            fh.write(self.render())


# ---- shape builders (return path "d" strings) ----------------------------

def blob_path(cx, cy, rx, ry, wobble=0.0, n=8, phase=0.0, squash_bottom=0.0):
    """A soft closed blob through n points (Catmull-Rom -> cubic Beziers)."""
    pts = []
    for i in range(n):
        a = phase + i * 2 * math.pi / n
        k = 1.0 + wobble * math.sin(i * 2.399 + phase * 3.1)
        x = cx + math.cos(a) * rx * k
        y = cy + math.sin(a) * ry * k
        if squash_bottom and y > cy:
            y = cy + (y - cy) * (1.0 - squash_bottom)
        pts.append((x, y))
    return smooth_closed(pts)


def smooth_closed(pts, tension=0.5):
    n = len(pts)
    d = "M%s %s" % (f(pts[0][0]), f(pts[0][1]))
    for i in range(n):
        p0 = pts[(i - 1) % n]
        p1 = pts[i]
        p2 = pts[(i + 1) % n]
        p3 = pts[(i + 2) % n]
        c1 = (p1[0] + (p2[0] - p0[0]) * tension / 3.0, p1[1] + (p2[1] - p0[1]) * tension / 3.0)
        c2 = (p2[0] - (p3[0] - p1[0]) * tension / 3.0, p2[1] - (p3[1] - p1[1]) * tension / 3.0)
        d += " C%s %s %s %s %s %s" % (f(c1[0]), f(c1[1]), f(c2[0]), f(c2[1]), f(p2[0]), f(p2[1]))
    return d + " Z"


def smooth_open(pts, tension=0.5):
    n = len(pts)
    d = "M%s %s" % (f(pts[0][0]), f(pts[0][1]))
    for i in range(n - 1):
        p0 = pts[max(i - 1, 0)]
        p1 = pts[i]
        p2 = pts[i + 1]
        p3 = pts[min(i + 2, n - 1)]
        c1 = (p1[0] + (p2[0] - p0[0]) * tension / 3.0, p1[1] + (p2[1] - p0[1]) * tension / 3.0)
        c2 = (p2[0] - (p3[0] - p1[0]) * tension / 3.0, p2[1] - (p3[1] - p1[1]) * tension / 3.0)
        d += " C%s %s %s %s %s %s" % (f(c1[0]), f(c1[1]), f(c2[0]), f(c2[1]), f(p2[0]), f(p2[1]))
    return d


def star_path(cx, cy, r_out, r_in, points=5, rot=-90):
    pts = []
    for i in range(points * 2):
        r = r_out if i % 2 == 0 else r_in
        a = math.radians(rot + i * 180.0 / points)
        pts.append((cx + math.cos(a) * r, cy + math.sin(a) * r))
    return "M" + " L".join("%s %s" % (f(x), f(y)) for x, y in pts) + " Z"


def rounded_poly(pts, r):
    """Polygon with rounded corners (quadratic corners)."""
    n = len(pts)
    d = ""
    for i in range(n):
        p0 = pts[(i - 1) % n]
        p1 = pts[i]
        p2 = pts[(i + 1) % n]
        def toward(a, b, dist):
            dx, dy = b[0] - a[0], b[1] - a[1]
            L = math.hypot(dx, dy) or 1.0
            t = min(dist / L, 0.5)
            return (a[0] + dx * t, a[1] + dy * t)
        a = toward(p1, p0, r)
        b = toward(p1, p2, r)
        d += ("M" if i == 0 else " L") + "%s %s" % (f(a[0]), f(a[1]))
        d += " Q%s %s %s %s" % (f(p1[0]), f(p1[1]), f(b[0]), f(b[1]))
    return d + " Z"


# ---- the shared character recipe -----------------------------------------

def soft_body(svg, d, base, outline=OUTLINE, sw=OUTLINE_W, light=(0.36, 0.3), shade_amount=0.2):
    """Fill a closed path with the standard soft shading + outline."""
    grad = svg.radial([(0, lighten(base, 0.38)), (0.55, base), (1, darken(base, shade_amount))], cx=light[0], cy=light[1], r=0.85)
    svg.path(d, fill=grad, stroke=outline, sw=sw)


def gloss(svg, cx, cy, rx, ry, rot=-25, opacity=0.6):
    svg.ellipse(cx, cy, rx, ry, "#ffffff", opacity=opacity, rot=rot)


def eye(svg, cx, cy, r, iris="#7a5cc0", look=(0.0, 0.0), closed=False, happy=False):
    """Glossy chibi eye. closed -> a soft arc; happy -> an upturned arc."""
    if closed or happy:
        s = r * 0.9
        if happy:
            d = "M%s %s Q%s %s %s %s" % (f(cx - s), f(cy + s * 0.25), f(cx), f(cy - s * 0.9), f(cx + s), f(cy + s * 0.25))
        else:
            d = "M%s %s Q%s %s %s %s" % (f(cx - s), f(cy - s * 0.1), f(cx), f(cy + s * 0.7), f(cx + s), f(cy - s * 0.1))
        svg.path(d, stroke=OUTLINE, sw=max(3.0, r * 0.36))
        return
    lx, ly = look[0] * r * 0.18, look[1] * r * 0.18
    svg.ellipse(cx, cy, r * 0.82, r, "#2a1238")
    svg.ellipse(cx + lx, cy + ly + r * 0.12, r * 0.6, r * 0.72, iris)
    svg.ellipse(cx + lx, cy + ly + r * 0.3, r * 0.42, r * 0.44, lighten(iris, 0.35), opacity=0.8)
    svg.ellipse(cx + lx, cy + ly - r * 0.05, r * 0.36, r * 0.46, "#1c0b29")
    svg.circle(cx - r * 0.28 + lx, cy - r * 0.38 + ly, r * 0.3, "#ffffff")
    svg.circle(cx + r * 0.3 + lx, cy + r * 0.34 + ly, r * 0.14, "#ffffff", opacity=0.9)


def blush(svg, cx, cy, rx, ry, color="#f5a2a8", opacity=0.75):
    grad = svg.radial([(0, color, opacity), (1, color, 0)])
    svg.ellipse(cx, cy, rx, ry, grad)


def smile(svg, cx, cy, w, open_mouth=False, color=OUTLINE):
    if open_mouth:
        d = "M%s %s Q%s %s %s %s Q%s %s %s %s Z" % (f(cx - w), f(cy), f(cx), f(cy + w * 1.5), f(cx + w), f(cy), f(cx), f(cy + w * 0.25), f(cx - w), f(cy))
        svg.path(d, fill="#b23a48", stroke=color, sw=3.5)
        svg.ellipse(cx, cy + w * 0.75, w * 0.45, w * 0.3, "#ff8fa0")
    else:
        d = "M%s %s Q%s %s %s %s" % (f(cx - w), f(cy), f(cx), f(cy + w * 0.9), f(cx + w), f(cy))
        svg.path(d, stroke=color, sw=3.5)


def ground_shadow(svg, cx, cy, rx, ry=None, opacity=0.22):
    ry = ry if ry is not None else rx * 0.28
    grad = svg.radial([(0, "#2a1238", opacity), (1, "#2a1238", 0)])
    svg.ellipse(cx, cy, rx, ry, grad)
