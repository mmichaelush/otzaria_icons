import 'package:flutter_test/flutter_test.dart';

import 'generated/icon_expectations.dart';

void main() {
  test('generated IconData uses the package font', () {
    expect(generatedIconExpectations, isNotEmpty);
    expect(
      generatedIconExpectations.values.map((icon) => icon.codePoint).toSet(),
      hasLength(generatedIconExpectations.length),
    );
    for (final icon in generatedIconExpectations.values) {
      expect(icon.fontFamily, 'OtzariaIcons');
      expect(icon.fontPackage, 'otzaria_icons');
    }
  });
}
