# otzaria_icons example

A visual gallery of every icon in the `otzaria_icons` package. Use it to browse
the full set, preview each glyph at different sizes, and check regular/filled
variants and RTL rendering.

## Run it

```console
cd example
flutter pub get
flutter run
```

Pick any connected device or desktop/web target. The gallery reads the generated
`lib/generated/icon_catalog.dart`, so it always reflects the current icon set.

## What it shows

- Every icon rendered from the packaged `OtzariaIcons` font.
- A size control to preview glyphs from small (16 px) to large.
- Light/dark and text-direction toggles to sanity-check contrast and RTL
  mirroring.

## Using an icon in your own app

```dart
import 'package:otzaria_icons/otzaria_icons.dart';

const Icon(OtzariaIcons.book_open_large_24_regular);
```

To look an icon up by name or build a picker, use the generated index:

```dart
final icon = OtzariaIcons.allIcons['book_open_large_24_regular'];
```

See the repository `README.md` and `docs/usage.md` for the full API.
