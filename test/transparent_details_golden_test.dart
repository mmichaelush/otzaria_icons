import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria_icons/otzaria_icons.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUpAll(() async {
    final fontData = rootBundle.load(
      'packages/otzaria_icons/lib/fonts/otzaria_icons.otf',
    );
    await (FontLoader('packages/otzaria_icons/OtzariaIcons')..addFont(fontData))
        .load();
  });

  testWidgets('transparent details survive SVG to font conversion', (
    tester,
  ) async {
    const icons = <String, IconData>{
      'book_zim_24_filled': OtzariaIcons.book_zim_24_filled,
      'book_word_24_filled': OtzariaIcons.book_word_24_filled,
      'book_upload_24_filled': OtzariaIcons.book_upload_24_filled,
      'book_pdf_24_filled': OtzariaIcons.book_pdf_24_filled,
      'book_search_24_filled': OtzariaIcons.book_search_24_filled,
      'book_link_24_filled': OtzariaIcons.book_link_24_filled,
      'book_hyperlink_24_regular': OtzariaIcons.book_hyperlink_24_regular,
      'bookshelf_24_regular': OtzariaIcons.bookshelf_24_regular,
      'book_open_large_search_24_filled':
          OtzariaIcons.book_open_large_search_24_filled,
    };
    tester.view.physicalSize = const Size(600, 804);
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
              children: [
                for (final entry in icons.entries)
                  SizedBox(
                    height: 84,
                    child: Row(
                      children: [
                        for (final size in [24.0, 48.0, 72.0])
                          Container(
                            width: 180,
                            height: 76,
                            alignment: Alignment.center,
                            color: const Color(0xFFE6B85C),
                            child: Icon(entry.value,
                                size: size, color: Colors.black),
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
      matchesGoldenFile('goldens/transparent_details.png'),
    );
  }, skip: !Platform.isWindows);
}
