# Testing and CI

## Local validation

Run from the repository root:

```console
flutter pub get
dart run tool/validate.dart
dart run tool/generate.dart --check
flutter analyze
flutter test
```

The package tests cover:

- stable codepoint/font metadata;
- agreement between SVG, manifest, and generated API;
- actual widget rendering of every glyph;
- a Windows-only visual golden containing the complete catalog.

The golden runs on one fixed CI operating system to avoid cross-platform font
rasterization differences.

## Example gallery

```console
cd example
flutter pub get
flutter analyze
flutter test
flutter run
```

The gallery is the human visual acceptance test. Review light/dark, LTR/RTL,
regular/filled, and sizes 16, 20, 24, 32, and 48.

## Tree-shaking app

`test_apps/minimal/` references one icon only. Its release build must complete
without a non-constant `IconData` warning. `tool/check_font_subset.dart` verifies
that Flutter's output font is smaller than the complete package font.

## GitHub Actions

The main CI workflow runs:

- package analysis/tests on minimum and current Flutter;
- read-only generated-file drift validation;
- example analysis/tests;
- Web tree-shaking release build and numeric subset assertion;
- Android release builds for minimal and gallery applications;
- Windows golden and release builds.

Release validation additionally covers Linux and macOS desktop builds before a
version tag is created. CI must pass from a clean checkout; local SDKs, caches,
IDE files, and build outputs are intentionally ignored.

## When to update tests

Adding icons updates generated expectations and the complete gallery golden.
Changing generator/config/font behavior also requires rerunning the
tree-shaking proof. Intentional visual changes require reviewing and replacing
the golden on Windows, then explaining the change in the pull request.

