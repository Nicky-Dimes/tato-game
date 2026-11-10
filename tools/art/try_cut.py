#!/usr/bin/env python3
"""Dev helper: try a cut and write a contact sheet to look at.
   python3 tools/art/try_cut.py <sheet.png> x0,y0,x1,y1 <count> <mode> <out.png> [merge] [key=value ...]"""
import sys, os
sys.path.insert(0, os.path.dirname(os.path.abspath(__file__)))
from cutter import cut_panel, contact_sheet

sheet = sys.argv[1]
rect = tuple(int(v) for v in sys.argv[2].split(","))
count = int(sys.argv[3])
mode = sys.argv[4]
out = sys.argv[5]
merge = int(sys.argv[6]) if len(sys.argv) > 6 else 0
kw = {}
for a in sys.argv[7:]:
    k, v = a.split("=")
    kw[k] = int(v) if v.lstrip("-").isdigit() else (v == "True" if v in ("True", "False") else v)
cuts = cut_panel(sheet, rect, count, mode, merge=merge, **kw)
for c in cuts:
    print(c["origin"], c["w"], c["h"])
contact_sheet(cuts, out, cell=int(os.environ.get("CELL", "140")), cols=int(os.environ.get("COLS", "8")))
