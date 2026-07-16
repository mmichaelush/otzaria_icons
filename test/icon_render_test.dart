import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/icon_expectations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fontData = rootBundle.load('packages/otzaria_icons/'
        'lib/fonts/otzaria_icons.otf');
    await (FontLoader('packages/otzaria_icons/OtzariaIcons')..addFont(fontData))
        .load();
  });

  testWidgets('every generated glyph renders', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Wrap(
          textDirection: TextDirection.ltr,
          children: [
            for (final icon in generatedIconExpectations.values)
              Icon(icon, size: 24),
          ],
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(
      find.byType(Icon),
      findsNWidgets(generatedIconExpectations.length),
    );
    expect(tester.takeException(), isNull);
  });
}
