import 'package:flutter_test/flutter_test.dart';
import 'package:otzaria_icons/otzaria_icons.dart';

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

  test('allIcons exposes every icon, keyed by name', () {
    // The public runtime index consumers use for pickers / name lookup must
    // stay in lockstep with the generated icon set.
    expect(OtzariaIcons.allIcons, isNotEmpty);
    expect(
      OtzariaIcons.allIcons.keys.toSet(),
      generatedIconExpectations.keys.toSet(),
    );
    for (final entry in generatedIconExpectations.entries) {
      expect(
        OtzariaIcons.allIcons[entry.key],
        entry.value,
        reason: '${entry.key} missing or mismatched in allIcons',
      );
    }
  });
}
