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

  testWidgets('visual gallery at production sizes', (tester) async {
    tester.view.physicalSize = const Size(800, 900);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);

    await tester.pumpWidget(
      MaterialApp(
        home: ColoredBox(
          color: Colors.white,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                for (final entry in generatedIconExpectations.entries)
                  SizedBox(
                    height: 84,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        for (final size in [16.0, 20.0, 24.0, 32.0, 48.0])
                          Container(
                            width: 140,
                            height: 72,
                            alignment: Alignment.center,
                            color: size == 24
                                ? const Color(0xFFF1F6FF)
                                : const Color(0xFFF8F8F8),
                            child: Icon(
                              entry.value,
                              size: size,
                              color: Colors.black,
                            ),
                          ),
                      ],
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
