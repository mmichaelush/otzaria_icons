# Release process

## Version policy

During pre-1.0 development:

- `0.1.x`: documentation, pipeline fixes, and small non-semantic visual fixes;
- `0.x.0`: new icons, substantial redesign, semantic changes, or RTL changes.

After 1.0, public name/codepoint removal or incompatible behavior requires a
major version. Codepoints are never recycled.

## Release checklist

1. Confirm every new icon's authorship, license, and provenance fields.
2. Review `upstream_status` against the current official Fluent catalog.
3. Update the version in `pubspec.yaml`.
4. Move changelog entries into a heading matching that version and date.
5. Run generation and confirm the repository remains current:

   ```console
   dart run tool/generate.dart
   dart run tool/generate.dart --check
   flutter analyze
   flutter test
   ```

6. Validate the example gallery visually.
7. Build Android and Windows release applications.
8. Run GitHub's Linux/macOS release-validation workflow.
9. If `publish_to: none` is removed in the future, add
   `dart pub publish --dry-run` as a package-content check.
10. Merge only after all required GitHub checks pass.
11. Create an annotated tag `v<pubspec version>` on the release commit and push
    it.
12. Update Otzaria's Git dependency `ref`, run its tests, and review affected
    screens.

Never create the tag before CI passes. Never move or overwrite a published tag;
release a new patch/minor version instead.

## 1.0 readiness

Version 1.0.0 requires proven deterministic generation, stable codepoints,
working package font loading and tree-shaking, and successful release builds on
Android, Windows, Linux, and macOS.
