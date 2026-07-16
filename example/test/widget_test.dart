import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria_icons_example/generated/icon_catalog.dart';
import 'package:otzaria_icons_example/main.dart';

void main() {
  testWidgets('gallery lists every current icon', (tester) async {
    await tester.pumpWidget(const IconGalleryApp());

    expect(iconCatalog, isNotEmpty);
    expect(
      iconCatalog.map((icon) => icon.name).toSet(),
      hasLength(iconCatalog.length),
    );
    expect(find.text(iconCatalog.first.name), findsOneWidget);
  });
}
