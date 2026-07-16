import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'generated/icon_expectations.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fontData = rootBundle.load(
      'packages/otzaria_icons/lib/fonts/otzaria_icons.otf',
    );
    await (FontLoader('packages/otzaria_icons/OtzariaIcons')..addFont(fontData))
        .load();
  });

  testWidgets('visual gallery', (tester) async {
    tester.view.physicalSize = const Size(1000, 700);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Wrap(
              alignment: WrapAlignment.center,
              runAlignment: WrapAlignment.center,
              children: [
                for (final entry in generatedIconExpectations.entries)
                  SizedBox(
                    width: 180,
                    height: 110,
                    child: Center(
                      child: Icon(entry.value, size: 80, color: Colors.black),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
    await expectLater(
      find.byType(ColoredBox).first,
      matchesGoldenFile('goldens/icon_gallery.png'),
    );
  }, skip: !Platform.isWindows);
}
