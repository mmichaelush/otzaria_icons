#!/usr/bin/env python3
"""Rewrite each glyph outline in the generated OTF directly from its source SVG.

WHY THIS EXISTS
---------------
`icon_font_generator` builds the OTF from the SVG sources, but its outline
converter distorts a few complex glyphs even when the source is a clean, single,
correctly-wound path: it translated `book_open_large_search_24_filled` ~4 units
left and mangled contours in `stander_24_filled` / `search_in_the_text_24_regular`.
These defects are internal to the pinned generator and unrelated to the source.

This step runs AFTER `dart run tool/generate.dart`. For every non-knockout icon
it rebuilds the CFF charstring straight from the committed source path, mapping
the 24x24 canvas onto the em (y-flipped) with no re-fitting, so the font geometry
is byte-for-byte what the source (and docs/icon_catalog.svg) show. All font
structure, names, codepoints, advance widths, and metadata produced by the
generator are preserved untouched.

Intended interior knockouts (document_word, document_bullet_list, book_open_alef)
rely on the generator's winding reconciliation across their multiple paths and
already render correctly, so they are detected and left exactly as generated.

Deterministic: identical sources produce an identical charstring, and the OTF
head timestamp set by the generator is preserved, so `generate.dart --check`
stays reproducible when this step is part of the pipeline.

Requires: skia-pathops, fonttools.
"""
import sys, os, re, yaml

try:
    import pathops
    from fontTools.ttLib import TTFont
    from fontTools.svgLib.path import parse_path
    from fontTools.pens.t2CharStringPen import T2CharStringPen
    from fontTools.pens.transformPen import TransformPen
except ImportError as e:
    sys.exit("Missing dependency: %s. Run: pip install skia-pathops fonttools" % e)

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
PATH_RE = re.compile(r'<path\b([^>]*?)/?>')
D_RE = re.compile(r'\bd\s*=\s*"([^"]*)"')
FR_RE = re.compile(r'fill-rule\s*=\s*"([^"]*)"')


def read_paths(text):
    out = []
    for m in PATH_RE.finditer(text):
        d = D_RE.search(m.group(1))
        fr = FR_RE.search(m.group(1))
        if d:
            out.append((d.group(1), fr.group(1) if fr else "nonzero"))
    return out


def is_knockout(paths):
    if len(paths) < 2:
        return False
    simps = []
    for d, fr in paths:
        p = pathops.Path()
        parse_path(d, p.getPen())
        p.fillType = (pathops.FillType.EVEN_ODD if fr == "evenodd"
                      else pathops.FillType.WINDING)
        simps.append(pathops.simplify(p))
    for i, pi in enumerate(simps):
        others = [s for j, s in enumerate(simps) if j != i]
        u = pathops.Path()
        pathops.union(others, u.getPen())
        inter = pathops.Path()
        pathops.intersection([pi], [u], inter.getPen())
        if abs(pi.area) > 1e-6 and abs(inter.area) / abs(pi.area) > 0.97:
            return True
    return False


def main(argv):
    check = "--check" in argv
    cfg = yaml.safe_load(open(os.path.join(ROOT, "tool", "config.yaml")))
    font_path = os.path.join(ROOT, cfg["font_file"])
    src_dir = os.path.join(ROOT, cfg["source_directory"])
    manifest = yaml.safe_load(open(os.path.join(ROOT, cfg["manifest_file"])))

    # recalcTimestamp=False preserves the generator's fixed head timestamp so
    # the repaired OTF stays byte-for-byte reproducible.
    font = TTFont(font_path, recalcTimestamp=False)
    upm = font["head"].unitsPerEm
    scale = upm / 24.0
    cmap = font.getBestCmap()
    hmtx = font["hmtx"]
    cff = font["CFF "].cff
    top = cff[cff.fontNames[0]]
    charStrings = top.CharStrings
    # 24x24 canvas (y-down) -> em (y-up): scale(scale,-scale), translate(0,upm)
    transform = (scale, 0, 0, -scale, 0, upm)

    rebuilt, skipped = [], []
    for icon in manifest["icons"]:
        name = icon["name"]
        glyph_name = cmap[icon["codepoint"]]
        paths = read_paths(open(os.path.join(src_dir, name + ".svg")).read())
        if is_knockout(paths):
            skipped.append(name)
            continue
        advance = hmtx[glyph_name][0]
        pen = T2CharStringPen(advance, None)
        tpen = TransformPen(pen, transform)
        for d, _ in paths:
            parse_path(d, tpen)
        cs = pen.getCharString(private=top.Private)
        rebuilt.append((glyph_name, cs, name))

    if check:
        # Report only whether the on-disk glyphs already match the sources.
        mismatched = []
        for glyph_name, cs, name in rebuilt:
            if charStrings[glyph_name].compile() != cs.compile():
                mismatched.append(name)
        for n in mismatched:
            print("STALE-GLYPH  %s" % n)
        print("%d glyph(s) differ from source, %d knockout(s) skipped."
              % (len(mismatched), len(skipped)))
        return 1 if mismatched else 0

    for glyph_name, cs, _ in rebuilt:
        charStrings[glyph_name] = cs
    font.save(font_path)
    print("Repaired %d glyph(s) from source; left %d knockout(s) untouched."
          % (len(rebuilt), len(skipped)))
    return 0


if __name__ == "__main__":
    sys.exit(main(sys.argv[1:]))
