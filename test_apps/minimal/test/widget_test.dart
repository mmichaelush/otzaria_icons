import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria_icons_minimal/main.dart';

void main() {
  testWidgets('the single selected icon is present', (tester) async {
    await tester.pumpWidget(const MinimalIconApp());
    expect(find.byType(MinimalIconApp), findsOneWidget);
  });
}
