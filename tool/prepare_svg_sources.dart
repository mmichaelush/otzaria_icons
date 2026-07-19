import 'dart:io';
import 'dart:math' as math;

import 'package:path_parsing/path_parsing.dart';
import 'package:xml/xml.dart';

/// Converts visually valid but font-incompatible SVGs into canonical sources.
///
/// Inkscape is used as the standards-compliant renderer for strokes, shapes,
/// text, masks, and nested transforms. The resulting vector PDF is imported
/// back to SVG, after which this tool flattens all transforms into direct
/// 24x24 path coordinates. No raster data is accepted in the final result.
void main(List<String> arguments) {
  if (arguments.isEmpty) {
    stderr.writeln(
      'Usage: dart run tool/prepare_svg_sources.dart <svg> [<svg> ...]',
    );
    exitCode = 64;
    return;
  }

  final inkscape = _findInkscape();
  final temp = Directory('.dart_tool/svg_prepare')..createSync(recursive: true);

  for (final fileName in arguments) {
    final sourceFile = File(fileName);
    final original = sourceFile.readAsStringSync();
    final originalDocument = XmlDocument.parse(original);
    final hasMask = originalDocument.descendants
        .whereType<XmlElement>()
        .any((element) => element.name.local == 'mask');
    final prepared = _prepareForInkscape(originalDocument, hasMask);
    final stem = sourceFile.uri.pathSegments.last.replaceAll('.svg', '');
    final preparedFile = File('${temp.path}/$stem.prepared.svg')
      ..writeAsStringSync(prepared);
    final pdfFile = File('${temp.path}/$stem.pdf');
    final importedFile = File('${temp.path}/$stem.imported.svg');
    if (pdfFile.existsSync()) pdfFile.deleteSync();
    if (importedFile.existsSync()) importedFile.deleteSync();

    _runInkscape(inkscape, [
      preparedFile.absolute.path,
      '--actions=select-all:all;object-stroke-to-path',
      '--export-type=pdf',
      '--export-text-to-path',
      '--export-filename=${pdfFile.absolute.path}',
    ]);
    _waitFor(pdfFile);
    _runInkscape(inkscape, [
      pdfFile.absolute.path,
      '--export-plain-svg',
      '--export-filename=${importedFile.absolute.path}',
    ]);
    _waitFor(importedFile);

    final canonical = _canonicalize(
      XmlDocument.parse(importedFile.readAsStringSync()),
      combineEvenOdd: hasMask,
    );
    sourceFile.writeAsStringSync(canonical);
    stdout.writeln('Prepared $fileName${hasMask ? ' (mask flattened)' : ''}');
  }
}

String _findInkscape() {
  final configured = Platform.environment['INKSCAPE'];
  final candidates = [
    if (configured != null) configured,
    r'C:\Program Files\Inkscape\bin\inkscape.exe',
    'inkscape',
  ];
  for (final candidate in candidates) {
    if (candidate == 'inkscape' || File(candidate).existsSync()) {
      return candidate;
    }
  }
  throw StateError(
    'Inkscape was not found. Install it or set the INKSCAPE environment variable.',
  );
}

String _prepareForInkscape(XmlDocument document, bool hasMask) {
  final root = document.rootElement;
  final width = root.getAttribute('width') ?? '24';
  final height = root.getAttribute('height') ?? '24';
  final viewBox = root.getAttribute('viewBox') ?? '0 0 $width $height';

  Iterable<XmlElement> content;
  if (hasMask) {
    final masks = document.descendants
        .whereType<XmlElement>()
        .where((element) => element.name.local == 'mask')
        .toList();
    if (masks.length != 1) {
      throw const FormatException('Exactly one mask is supported per icon');
    }
    content = masks.single.children.whereType<XmlElement>();
  } else {
    content = root.children.whereType<XmlElement>().where(
          (element) => element.name.local != 'defs',
        );
  }

  var body = content.map((element) => element.toXmlString()).join('\n');
  body = body
      .replaceAll(RegExp(r'\s+transform-origin="center"'), '')
      .replaceAll(
          'transform="scale(-1, 1)"', 'transform="translate(24 0) scale(-1 1)"')
      .replaceAll('fill="white"', 'fill="black"');
  const inheritedNames = {
    'color',
    'fill',
    'fill-opacity',
    'fill-rule',
    'stroke',
    'stroke-width',
    'stroke-linecap',
    'stroke-linejoin',
    'stroke-miterlimit',
    'stroke-opacity',
    'opacity',
    'style',
  };
  final inherited = root.attributes
      .where((attribute) => inheritedNames.contains(attribute.name.local))
      .map(
        (attribute) =>
            '${attribute.name.local}="${attribute.value.replaceAll('&', '&amp;').replaceAll('"', '&quot;')}"',
      )
      .join(' ');
  if (inherited.isNotEmpty) body = '<g $inherited>$body</g>';
  return '<svg xmlns="http://www.w3.org/2000/svg" width="$width" '
      'height="$height" viewBox="$viewBox">$body</svg>\n';
}

void _runInkscape(String executable, List<String> arguments) {
  final result = Process.runSync(executable, arguments, runInShell: false);
  if (result.exitCode != 0) {
    throw ProcessException(
      executable,
      arguments,
      '${result.stdout}\n${result.stderr}',
      result.exitCode,
    );
  }
}

void _waitFor(File file) {
  for (var attempt = 0; attempt < 100; attempt++) {
    if (file.existsSync() && file.lengthSync() > 0) return;
    sleep(const Duration(milliseconds: 100));
  }
  throw FileSystemException('Inkscape did not create output', file.path);
}

String _canonicalize(XmlDocument document, {required bool combineEvenOdd}) {
  final root = document.rootElement;
  final viewBox = (root.getAttribute('viewBox') ?? '0 0 24 24')
      .split(RegExp(r'[\s,]+'))
      .map(double.parse)
      .toList();
  if (viewBox.length != 4 || viewBox[2] <= 0 || viewBox[3] <= 0) {
    throw const FormatException('Invalid imported viewBox');
  }
  final scale = math.min(24 / viewBox[2], 24 / viewBox[3]);
  final viewport = _Matrix(
    scale,
    0,
    0,
    scale,
    (24 - viewBox[2] * scale) / 2 - viewBox[0] * scale,
    (24 - viewBox[3] * scale) / 2 - viewBox[1] * scale,
  );

  final unsupported = document.descendants.whereType<XmlElement>().where(
        (element) => {'image', 'text', 'mask', 'filter'}.contains(
          element.name.local,
        ),
      );
  if (unsupported.isNotEmpty) {
    throw FormatException(
      'Inkscape output contains unsupported raster/text/mask content: '
      '${unsupported.map((element) => element.name.local).toSet()}',
    );
  }

  final paths = <_CanonicalPath>[];
  void visit(XmlElement element, _Matrix parent, {bool inDefinitions = false}) {
    final local = _parseTransform(element.getAttribute('transform'));
    final transform = viewport * parent * local;
    final definitions =
        inDefinitions || {'defs', 'clipPath'}.contains(element.name.local);
    if (element.name.local == 'path' && !definitions) {
      final data = element.getAttribute('d');
      if (data != null && data.trim().isNotEmpty) {
        final writer = _PathWriter(transform);
        writeSvgPathDataToPath(data, writer);
        final style = element.getAttribute('style') ?? '';
        final evenOdd = element.getAttribute('fill-rule') == 'evenodd' ||
            style.contains('fill-rule:evenodd');
        paths.add(_CanonicalPath(writer.result, evenOdd));
      }
    }
    for (final child in element.children.whereType<XmlElement>()) {
      visit(child, parent * local, inDefinitions: definitions);
    }
  }

  visit(root, const _Matrix.identity());
  if (paths.isEmpty) {
    throw const FormatException('No vector paths survived import');
  }

  final buffer = StringBuffer(
    '<svg xmlns="http://www.w3.org/2000/svg" width="24" height="24" '
    'viewBox="0 0 24 24">',
  );
  if (combineEvenOdd) {
    buffer
      ..write('<path fill-rule="evenodd" d="')
      ..write(paths.map((path) => path.data).join())
      ..write('"/>');
  } else {
    for (final path in paths) {
      buffer
        ..write('<path')
        ..write(path.evenOdd ? ' fill-rule="evenodd"' : '')
        ..write(' d="${path.data}"/>');
    }
  }
  buffer.write('</svg>\n');
  return buffer.toString();
}

class _CanonicalPath {
  const _CanonicalPath(this.data, this.evenOdd);

  final String data;
  final bool evenOdd;
}

class _PathWriter extends PathProxy {
  _PathWriter(this.transform);

  final _Matrix transform;
  final StringBuffer _buffer = StringBuffer();
  String get result => _buffer.toString();

  @override
  void moveTo(double x, double y) {
    final point = transform.apply(x, y);
    _buffer.write('M${_number(point.x)} ${_number(point.y)}');
  }

  @override
  void lineTo(double x, double y) {
    final point = transform.apply(x, y);
    _buffer.write('L${_number(point.x)} ${_number(point.y)}');
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
    final p1 = transform.apply(x1, y1);
    final p2 = transform.apply(x2, y2);
    final p3 = transform.apply(x3, y3);
    _buffer.write(
      'C${_number(p1.x)} ${_number(p1.y)} '
      '${_number(p2.x)} ${_number(p2.y)} '
      '${_number(p3.x)} ${_number(p3.y)}',
    );
  }

  @override
  void close() => _buffer.write('Z');
}

class _Point {
  const _Point(this.x, this.y);
  final double x;
  final double y;
}

class _Matrix {
  const _Matrix(this.a, this.b, this.c, this.d, this.e, this.f);
  const _Matrix.identity() : this(1, 0, 0, 1, 0, 0);

  final double a;
  final double b;
  final double c;
  final double d;
  final double e;
  final double f;

  _Point apply(double x, double y) => _Point(
        a * x + c * y + e,
        b * x + d * y + f,
      );

  _Matrix operator *(_Matrix other) => _Matrix(
        a * other.a + c * other.b,
        b * other.a + d * other.b,
        a * other.c + c * other.d,
        b * other.c + d * other.d,
        a * other.e + c * other.f + e,
        b * other.e + d * other.f + f,
      );
}

_Matrix _parseTransform(String? value) {
  if (value == null || value.trim().isEmpty) return const _Matrix.identity();
  var result = const _Matrix.identity();
  final expression = RegExp(r'([a-zA-Z]+)\s*\(([^)]*)\)');
  for (final match in expression.allMatches(value)) {
    final name = match.group(1)!;
    final values = RegExp(r'[-+]?(?:\d*\.\d+|\d+\.?)(?:[eE][-+]?\d+)?')
        .allMatches(match.group(2)!)
        .map((item) => double.parse(item.group(0)!))
        .toList();
    late final _Matrix operation;
    switch (name) {
      case 'matrix':
        if (values.length != 6) throw const FormatException('Invalid matrix');
        operation = _Matrix(
          values[0],
          values[1],
          values[2],
          values[3],
          values[4],
          values[5],
        );
      case 'translate':
        operation =
            _Matrix(1, 0, 0, 1, values[0], values.length > 1 ? values[1] : 0);
      case 'scale':
        operation = _Matrix(
            values[0], 0, 0, values.length > 1 ? values[1] : values[0], 0, 0);
      case 'rotate':
        final angle = values[0] * math.pi / 180;
        final rotation = _Matrix(math.cos(angle), math.sin(angle),
            -math.sin(angle), math.cos(angle), 0, 0);
        if (values.length == 3) {
          operation = _Matrix(1, 0, 0, 1, values[1], values[2]) *
              rotation *
              _Matrix(1, 0, 0, 1, -values[1], -values[2]);
        } else {
          operation = rotation;
        }
      case 'skewX':
        operation = _Matrix(1, 0, math.tan(values[0] * math.pi / 180), 1, 0, 0);
      case 'skewY':
        operation = _Matrix(1, math.tan(values[0] * math.pi / 180), 0, 1, 0, 0);
      default:
        throw FormatException('Unsupported transform: $name');
    }
    result = result * operation;
  }
  return result;
}

String _number(double value) {
  final rounded = value.toStringAsFixed(6);
  return rounded
      .replaceFirst(RegExp(r'0+$'), '')
      .replaceFirst(RegExp(r'\.$'), '')
      .replaceFirst(RegExp(r'^-0$'), '0');
}
