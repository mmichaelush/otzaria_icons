# Contributing

Thank you for helping extend Otzaria's icon vocabulary. Contributions must keep
the public API, font mapping, visual style, and licensing record stable.

## Before starting

- Search Microsoft Fluent UI System Icons for an existing equivalent.
- Search this package's manifest for an existing or deprecated equivalent.
- Confirm the icon has a concrete Otzaria use case.
- Decide whether a regular variant, filled variant, or both are needed.

This repository is an unofficial extension and is not affiliated with or
endorsed by Microsoft.

## Preparing SVG files

Add SVGs directly to `assets_src/svg/`. Follow the exact
`<name>_24_<regular|filled>.svg` naming scheme, convert strokes to filled paths,
and satisfy [SVG requirements](docs/svg_requirements.md) and the
[visual design specification](docs/icon_design_spec.md).

All current artwork is original and GPL-3.0-only. By contributing original
artwork, confirm that you have the right to release it under that license. A
third-party or derivative source requires complete provenance and license review
before inclusion; do not label derivative work as `custom`.

## Generation workflow

```console
flutter pub get
dart run tool/generate.dart
dart run tool/generate.dart --check
flutter analyze
flutter test
```

The generator allocates IDs/codepoints and updates all derived artifacts. Review
the new `icon_manifest.yaml` record. Do not edit generated Dart, font, catalog,
expectations, or notices files manually.

Existing IDs, names, and codepoints are immutable. Never reuse a codepoint or
delete a glyph to close a gap. A rename is implemented as a deprecated alias,
not as removal of the old API.

## Visual review

Run `example/` and inspect every new icon:

- regular and filled variants together;
- 16, 20, 24, 32, and 48 logical pixels;
- light and dark themes;
- LTR and RTL directions;
- optical alignment beside nearby Fluent icons;
- interior holes and small gaps;
- selected/unselected state relationship.

Update the Windows golden only after confirming the difference is intentional.

## Manifest provenance

Every record must accurately describe:

- stable `id`, public `name`, source, and codepoint;
- variant, size, directionality, and deprecation;
- whether Fluent now provides an equivalent;
- `custom` versus `modified_fluent` origin;
- author, license, and any upstream source/commit.

The release maintainer is responsible for reviewing `upstream_status` before
every release. If Fluent adds an equivalent, record it, deprecate the local API
with a migration path, and do not silently remove the glyph.

## Pull request checklist

- Generation check, analysis, and tests pass.
- Gallery review is complete.
- `CHANGELOG.md` describes the addition/change.
- Provenance and GPL compatibility are confirmed.
- No cache, local SDK, build output, or IDE files are included.
- Public names remain Fluent-compatible `snake_case`.

See [Adding icons](docs/adding_icons.md), [Testing and CI](docs/testing_and_ci.md),
and [Release process](docs/release_process.md).

