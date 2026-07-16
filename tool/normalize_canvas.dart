import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

const _sourceDirectory = 'assets_src/svg';
const _canvasSize = 24.0;
const _opticalSize = 20.0;

void main(List<String> arguments) {
  final directory = Directory(_sourceDirectory);
  final files = directory
      .listSync()
      .whereType<File>()
      .where((file) => p.extension(file.path).toLowerCase() == '.svg')
      .toList()
    ..sort((a, b) => a.path.compareTo(b.path));
  var changed = 0;

  for (final file in files) {
    final document = XmlDocument.parse(file.readAsStringSync());
    final svg = document.rootElement;
    final soleGroup = svg.childElements.length == 1 &&
            svg.firstElementChild?.name.local == 'g'
        ? svg.firstElementChild
        : null;
    final existingTransform = soleGroup?.getAttribute('transform');
    final singleScale = existingTransform == null
        ? null
        : RegExp(r'scale\(([-+.\deE]+)\)').firstMatch(existingTransform);
    if (singleScale != null) {
      final scale = singleScale.group(1)!;
      soleGroup!.setAttribute(
        'transform',
        existingTransform!.replaceFirst(
          singleScale.group(0)!,
          'scale($scale $scale)',
        ),
      );
      file.writeAsStringSync('${document.toXmlString()}\n');
      stdout.writeln(
        'Repaired uniform scale for icon_font_generator 4.1.0: '
        '${p.basename(file.path)}',
      );
      changed++;
    }
    final values = svg
        .getAttribute('viewBox')
        ?.trim()
        .split(RegExp(r'[\s,]+'))
        .map(double.tryParse)
        .toList();
    if (values == null ||
        values.length != 4 ||
        values.any((value) => value == null)) {
      stderr.writeln('ERROR: ${p.basename(file.path)} has invalid viewBox');
      exitCode = 1;
      continue;
    }

    final minX = values[0]!;
    final minY = values[1]!;
    final width = values[2]!;
    final height = values[3]!;
    if (minX == 0 && minY == 0 && width == 24 && height == 24) continue;
    if (width <= 0 || height <= 0) {
      stderr.writeln('ERROR: ${p.basename(file.path)} has empty viewBox');
      exitCode = 1;
      continue;
    }

    final scale = _opticalSize / (width > height ? width : height);
    final translateX = (_canvasSize - width * scale) / 2 - minX * scale;
    final translateY = (_canvasSize - height * scale) / 2 - minY * scale;
    final scaleText = _number(scale);
    final transform = 'translate(${_number(translateX)} '
        '${_number(translateY)}) scale($scaleText $scaleText)';
    final originalChildren = svg.children.map((child) => child.copy()).toList();
    svg.children
      ..clear()
      ..add(
        XmlElement(
          XmlName('g'),
          [XmlAttribute(XmlName('transform'), transform)],
          originalChildren,
        ),
      );
    svg.setAttribute('viewBox', '0 0 24 24');
    svg.setAttribute('width', '24');
    svg.setAttribute('height', '24');
    file.writeAsStringSync('${document.toXmlString()}\n');
    stdout.writeln(
      'Normalized ${p.basename(file.path)} from '
      '${_number(width)}×${_number(height)}.',
    );
    changed++;
  }

  stdout.writeln('Checked ${files.length} SVG file(s); normalized $changed.');
}

String _number(double value) {
  final text = value.toStringAsFixed(8);
  return text.replaceFirst(RegExp(r'\.?0+$'), '');
}
