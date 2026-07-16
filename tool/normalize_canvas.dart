import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

const _sourceDirectory = 'assets_src/svg';

void main(List<String> arguments) {
  final files = Directory(_sourceDirectory)
      .listSync()
      .whereType<File>()
      .where((file) => p.extension(file.path).toLowerCase() == '.svg')
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));

  for (final file in files) {
    final document = XmlDocument.parse(file.readAsStringSync());
    final svg = document.rootElement;
    if (svg.getAttribute('viewBox') != '0 0 24 24') {
      stderr.writeln(
        'ERROR: ${p.basename(file.path)} must be exported with final '
        '24x24 path coordinates. Automatic transform-based scaling is '
        'intentionally disabled because it degrades small icon glyphs.',
      );
      exitCode = 1;
    }
  }

  stdout.writeln(
    'Checked ${files.length} SVG file(s); all use a native 24x24 canvas.',
  );
}
