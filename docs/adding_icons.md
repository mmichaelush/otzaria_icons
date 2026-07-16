# Adding icons

## 1. Prepare source files

Place all SVGs directly in `assets_src/svg/`. A batch may contain one icon or
regular/filled pairs. Follow `docs/svg_requirements.md`.

## 2. Run generation

From the repository root:

```console
flutter pub get
dart run tool/generate.dart
```

Generation performs this sequence:

1. normalize supported canvases;
2. safely sanitize SVG structure;
3. validate SVG and existing manifest metadata;
4. add new manifest records and allocate `max(codepoint) + 1`;
5. build the OTF in explicit manifest/codepoint order;
6. verify actual generated glyph names and codepoints;
7. regenerate the public Dart API, gallery catalog, test expectations, and
   third-party notices;
8. format and analyze the generated public API.

New records receive an opaque stable ID such as `icon-0011`. Never change an ID
after allocation. Complete or correct the new manifest record if its provenance,
directionality, author, or upstream state differs from the defaults.

## 3. Review generated changes

Expected changes may include:

- `icon_manifest.yaml`;
- `lib/fonts/otzaria_icons.otf`;
- `lib/src/generated/otzaria_icons_data.dart`;
- `example/lib/generated/icon_catalog.dart`;
- `test/generated/icon_expectations.dart`;
- `THIRD_PARTY_NOTICES.md`.

Do not hand-edit generated artifacts. Fix the SVG, manifest, config, or generator
and regenerate.

## 4. Validate

```console
dart run tool/generate.dart --check
flutter analyze
flutter test
```

The `--check` mode generates in a temporary directory, compares all derived
artifacts, and leaves repository files untouched.

Run the example gallery and inspect every new glyph. Also build
`test_apps/minimal/` when generation or public `IconData` construction changes,
because it proves icon font tree-shaking.

## 5. Document and submit

- Add a `CHANGELOG.md` entry under the unreleased version.
- Explain the icon's intended product use in the pull request.
- Confirm authorship and GPL-3.0-only licensing, or provide complete third-party
  provenance.
- Include screenshots for visual changes when practical.

Existing codepoints are immutable. Never reorder, recycle, silently remove, or
manually compact them.

