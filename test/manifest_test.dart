import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:yaml/yaml.dart';

import 'generated/icon_expectations.dart';

void main() {
  test('manifest names and source SVG files match', () {
    final manifest =
        loadYaml(File('icon_manifest.yaml').readAsStringSync()) as YamlMap;
    final manifestNames = {
      for (final item in manifest['icons'] as YamlList)
        (item as YamlMap)['name'] as String,
    };
    final svgNames = Directory('assets_src/svg')
        .listSync()
        .whereType<File>()
        .where((file) => p.extension(file.path).toLowerCase() == '.svg')
        .map((file) => p.basenameWithoutExtension(file.path))
        .toSet();

    expect(manifestNames, svgNames);
  });

  test('manifest codepoints match every generated IconData field', () {
    final manifest =
        loadYaml(File('icon_manifest.yaml').readAsStringSync()) as YamlMap;
    final config =
        loadYaml(File('tool/config.yaml').readAsStringSync()) as YamlMap;
    final entries = (manifest['icons'] as YamlList).cast<YamlMap>();
    final start = _parseCodepoint(config['codepoint_start']);
    final ids = <String>{};

    expect(generatedIconExpectations.keys.toSet(), {
      for (final entry in entries) entry['name'] as String,
    });
    for (var index = 0; index < entries.length; index++) {
      final entry = entries[index];
      final name = entry['name'] as String;
      final codepoint = _parseCodepoint(entry['codepoint']);
      final iconData = generatedIconExpectations[name];

      expect(entry['id'], matches(RegExp(r'^icon-\d{4,}$')));
      expect(ids.add(entry['id'] as String), isTrue, reason: 'duplicate ID');
      expect(codepoint, start + index, reason: '$name is not contiguous');
      expect(iconData, isNotNull, reason: '$name has no generated IconData');
      expect(iconData!.codePoint, codepoint,
          reason: '$name codepoint mismatch');
      expect(iconData.fontFamily, 'OtzariaIcons');
      expect(iconData.fontPackage, 'otzaria_icons');
      expect(entry['source'], 'assets_src/svg/$name.svg');
      expect(entry['variant'], name.endsWith('_filled') ? 'filled' : 'regular');
      expect(entry['size'], 24);
      expect(entry['match_text_direction'], isA<bool>());
      expect(entry['deprecated'], isA<bool>());
      expect(entry['origin'], isIn(['custom', 'modified_fluent']));
      expect(entry['author'], isA<String>());
      expect(entry['license'], isNotEmpty);
      expect(
        entry['upstream_status'],
        isIn(['missing', 'available', 'not-applicable']),
      );
    }
  });
}

int _parseCodepoint(Object? value) {
  if (value is int) return value;
  return int.parse(
    (value! as String).replaceFirst(RegExp(r'^0x'), ''),
    radix: 16,
  );
}
