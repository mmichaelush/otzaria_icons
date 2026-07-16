import 'dart:io';

import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart';

/// Uniformly scales native SVG path geometry around the 24x24 canvas center.
void main(List<String> arguments) {
  if (arguments.length < 2) {
    stderr.writeln(
      'Usage: dart run tool/scale_svg_paths.dart <factor> <svg> [<svg> ...]',
    );
    exitCode = 64;
    return;
  }

  final factor = double.parse(arguments.first);
  if (factor <= 0) {
    throw ArgumentError.value(factor, 'factor', 'must be positive');
  }

  for (final fileName in arguments.skip(1)) {
    final file = File(fileName);
    final source = file.readAsStringSync();
    final document = XmlDocument.parse(source);
    if (document.rootElement.getAttribute('viewBox') != '0 0 24 24') {
      throw FormatException('$fileName: expected a 24x24 viewBox');
    }
    if (document.descendants.whereType<XmlElement>().any(
          (element) => element.getAttribute('transform') != null,
        )) {
      throw FormatException('$fileName: flatten existing transforms first');
    }

    final pathPattern = RegExp(r'\bd="([^"]*)"');
    final output = source.replaceAllMapped(pathPattern, (match) {
      final writer = _CenteredScaleWriter(factor);
      writeSvgPathDataToPath(match.group(1), writer);
      return 'd="${writer.result}"';
    });
    file.writeAsStringSync('${output.trimRight()}\n');
    stdout.writeln('Scaled $fileName by $factor around (12, 12)');
  }
}

class _CenteredScaleWriter extends PathProxy {
  _CenteredScaleWriter(this.factor);

  final double factor;
  final StringBuffer _buffer = StringBuffer();

  String get result => _buffer.toString();

  String _coordinate(double value) => _number(12 + (value - 12) * factor);

  @override
  void moveTo(double x, double y) {
    _buffer.write('M${_coordinate(x)} ${_coordinate(y)}');
  }

  @override
  void lineTo(double x, double y) {
    _buffer.write('L${_coordinate(x)} ${_coordinate(y)}');
  }

  @override
  void cubicTo(
    double x1,
    double y1,
    double x2,
    double y2,
    double x3,
    double y3,
  ) {
    _buffer.write(
      'C${_coordinate(x1)} ${_coordinate(y1)} '
      '${_coordinate(x2)} ${_coordinate(y2)} '
      '${_coordinate(x3)} ${_coordinate(y3)}',
    );
  }

  @override
  void close() => _buffer.write('Z');
}

String _number(double value) {
  final rounded = value.toStringAsFixed(6);
  return rounded
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '')
      .replaceFirst(RegExp(r'^-0$'), '0');
}
