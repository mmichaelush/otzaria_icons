#!/usr/bin/env python3
"""Assert every manifest codepoint maps to a real, non-empty glyph in the OTF.

WHY THIS EXISTS
---------------
The Flutter widget tests only prove that an `Icon` builds without throwing. A
missing or empty glyph still "renders" — as an invisible box or blank space
(tofu) — without raising, so those tests cannot catch a font that shipped with a
codepoint that has no outline. This is a direct, cross-platform check of the
built font: for every icon in the manifest it verifies the codepoint is present
in the font's `cmap` AND that its glyph actually contains drawing (a non-empty
bounding box). It complements tool/repair_glyphs.py (which checks the glyph
geometry matches the source) by guaranteeing no codepoint is blank.

USAGE
-----
  python3 tool/check_glyph_coverage.py            # exit 1 if any glyph is bad

Requires: fonttools.
"""
import os
import sys

try:
    import yaml
    from fontTools.ttLib import TTFont
    from fontTools.pens.boundsPen import ControlBoundsPen
except ImportError as e:
    sys.exit("Missing dependency: %s. Run: pip install fonttools pyyaml" % e)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))


def _parse_codepoint(value):
    if isinstance(value, int):
        return value
    return int(str(value).replace("0x", ""), 16)


def main():
    cfg = yaml.safe_load(open(os.path.join(ROOT, "tool", "config.yaml")))
    manifest = yaml.safe_load(open(os.path.join(ROOT, cfg["manifest_file"])))
    font = TTFont(os.path.join(ROOT, cfg["font_file"]))
    cmap = font.getBestCmap()
    glyph_set = font.getGlyphSet()

    missing_cp, empty_glyph = [], []
    for icon in manifest["icons"]:
        name = icon["name"]
        cp = _parse_codepoint(icon["codepoint"])
        glyph_name = cmap.get(cp)
        if glyph_name is None:
            missing_cp.append("%s (U+%04X)" % (name, cp))
            continue
        pen = ControlBoundsPen(glyph_set)
        glyph_set[glyph_name].draw(pen)
        # bounds is None for an outline-less glyph; that would render as tofu.
        if pen.bounds is None:
            empty_glyph.append("%s (U+%04X -> %s)" % (name, cp, glyph_name))

    for entry in missing_cp:
        print("MISSING-CODEPOINT  %s" % entry)
    for entry in empty_glyph:
        print("EMPTY-GLYPH        %s" % entry)

    total = len(manifest["icons"])
    bad = len(missing_cp) + len(empty_glyph)
    print("Checked %d icon(s): %d missing codepoint, %d empty glyph."
          % (total, len(missing_cp), len(empty_glyph)))
    if bad:
        print("Font has %d glyph(s) that would render as tofu." % bad)
        return 1
    print("All codepoints map to a non-empty glyph (no tofu).")
    return 0


if __name__ == "__main__":
    sys.exit(main())
