# SVG requirements

An SVG is accepted only when it satisfies the mechanical rules below and passes
visual review.

## File and naming

- Store files directly in `assets_src/svg/`; do not create one directory per
  icon.
- Use lowercase `snake_case`.
- Use the form `<name>_24_regular.svg` or `<name>_24_filled.svg`.
- Names must match `^[a-z][a-z0-9_]*_24_(regular|filled)$`.
- Avoid uppercase letters, hyphens, spaces, consecutive underscores, leading
  digits, missing size/variant, and Dart reserved words.

## Canvas and geometry

- Final `viewBox` must be exactly `0 0 24 24`.
- Keep geometry visually centered with a typical 20×20 optical area.
- Large source canvases may be proportionally normalized into that area by the
  pipeline, but the normalized result still requires visual review.
- Avoid geometry touching the canvas edge unless the design explicitly demands
  it.
- Multiple `<path>` elements are allowed.

## Paths

- Convert all strokes to closed, filled outlines before adding the file.
- Do not leave `stroke`, `stroke-width`, `<line>`, text, raster images, scripts,
  or embedded styles.
- Remove unnecessary wrapper groups.
- Use explicit `fill-rule="evenodd"` only where interior holes truly require
  it; otherwise prefer non-zero winding paths for maximum font compatibility.
- The generated font is monochrome. Color is supplied by Flutter's `Icon`.

## Safe sanitation

`tool/sanitize.dart` performs conservative cleanup. It only flattens a sole
wrapper group when doing so cannot discard transforms, clipping, identifiers, or
nested group behavior. It intentionally does not rewrite ambiguous geometry.

`tool/normalize_canvas.dart` handles supported non-24 canvases and emits an
explicit two-axis `scale(x y)` transform. This avoids a known
`icon_font_generator` 4.1.0 issue with one-argument scale transforms.

## Validation levels

Errors block generation: invalid XML, wrong name/viewBox, strokes, missing
paths, duplicate names/IDs/codepoints, bad provenance, or codepoints outside
`0xE000–0xF8FF`.

Warnings highlight suspicious but potentially valid content, such as an
unusually high path count. A warning requires human review even when generation
continues.

## Visual acceptance

Inspect regular and filled variants together at 16, 20, 24, 32, and 48 pixels,
in light/dark and LTR/RTL modes. Confirm optical centering, recognizability,
interior holes, consistent weight, spacing, and selected-state relationship.

