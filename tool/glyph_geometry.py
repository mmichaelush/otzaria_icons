#!/usr/bin/env python3
"""Shared geometry helpers for the glyph pipeline.

`normalize_svg_overlaps.py` (source preparation) and `repair_glyphs.py` (final
OTF rebuild) both need to decide whether one of an icon's paths is an intended
interior knockout — a white shape cut out of a solid body that only exists via
winding cancellation (the "W" in document_word, the alef in book_open_alef, the
bullets in document_bullet_list). Previously each script reimplemented that test
with its own copy of the 0.97 / 1e-6 constants; if they ever drifted, an icon
could be unioned in one step and cut in the other. This module is the single
source of truth for both the thresholds and the detection logic.

Requires: skia-pathops, fonttools.
"""
import pathops
from fontTools.svgLib.path import parse_path

# A path whose filled area lies at least this fraction inside the union of the
# other paths is treated as an intended interior knockout rather than an
# overlapping solid layer.
KNOCKOUT_INSIDE_RATIO = 0.97
# Filled areas below this (square units on the 24x24 canvas) are float noise.
AREA_EPS = 1e-6


def simplified(d, fill_rule):
    """Parse an SVG path `d` and return a simplified pathops.Path honouring its
    own fill-rule."""
    p = pathops.Path()
    parse_path(d, p.getPen())
    p.fillType = (pathops.FillType.EVEN_ODD if fill_rule == "evenodd"
                  else pathops.FillType.WINDING)
    return pathops.simplify(p)


def inside_union_ratio(simps, i):
    """Fraction of simps[i]'s filled area that lies inside the union of the
    other paths (0.0 when there are no others or the area is negligible)."""
    others = [s for j, s in enumerate(simps) if j != i]
    if not others:
        return 0.0
    u = pathops.Path()
    pathops.union(others, u.getPen())
    inter = pathops.Path()
    pathops.intersection([simps[i]], [u], inter.getPen())
    ai = abs(simps[i].area)
    return abs(inter.area) / ai if ai > AREA_EPS else 0.0


def is_knockout_index(simps, i):
    """True if simps[i] is an intended interior knockout."""
    return inside_union_ratio(simps, i) > KNOCKOUT_INSIDE_RATIO
