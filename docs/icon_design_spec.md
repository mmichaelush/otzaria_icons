# Icon design specification

## Canvas and optical bounds

- Canvas: 24×24 with `viewBox="0 0 24 24"`.
- Export final path geometry directly in 24×24 coordinates, with a centered
  20×20 optical area. Transform-based downscaling is not accepted.
- Keep geometry within the visual safe area; use optical centering.
- Geometry may exceed the nominal 2-unit margin only when required for optical
  balance and after visual review at small sizes.

## Weight and shape

- Regular icons should visually match Fluent UI's regular weight, approximately
  the visual result of a 1.5-unit stroke before expansion.
- Convert strokes to closed, filled paths before committing.
- Use explicit `fill-rule` for shapes with interior holes.
- Avoid unnecessary groups, transforms, masks, clipping, and embedded styles.
- Prefer Fluent-like rounded joins/endings and consistent corner radii; compare
  related icons side by side instead of applying a radius mechanically.
- Keep meaningful gaps visible at common sizes (16, 20, 24, and 32 px).
- Keep gaps around 1.5 units or larger where possible so they survive 16 px
  rendering.
- Use whole or half-pixel coordinates intentionally; avoid accidental precision
  noise from editor exports.

## Regular and filled relationship

- A filled variant is added only when the product needs a selected/active state.
- Filled icons must preserve the same silhouette, optical center, and semantic
  details as regular icons.
- Interior negative space may be simplified in filled variants, but the icon
  must remain recognizable at 16 px.

## Directionality

- Directional icons may have an RTL-mirrored counterpart; non-directional icons
  must not be mirrored automatically.
- Record intended mirroring in `match_text_direction`; do not infer it only from
  the current gallery language.

## Acceptance

Review at 16, 20, 24, 32, and 48 px in light/dark and LTR/RTL modes. Compare
baseline, perceived weight, spacing, corner language, and silhouette with nearby
official Fluent icons.
