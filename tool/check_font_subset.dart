import 'dart:io';

void main(List<String> arguments) {
  if (arguments.length != 2) {
    stderr.writeln(
      'Usage: dart run tool/check_font_subset.dart '
      '<source-font> <release-font>',
    );
    exitCode = 64;
    return;
  }

  final source = File(arguments[0]);
  final release = File(arguments[1]);
  if (!source.existsSync() || !release.existsSync()) {
    stderr.writeln(
      'ERROR: Missing source or release font: '
      '${source.path}, ${release.path}',
    );
    exitCode = 1;
    return;
  }

  final sourceSize = source.lengthSync();
  final releaseSize = release.lengthSync();
  if (releaseSize >= sourceSize) {
    stderr.writeln(
      'ERROR: Font was not subset: $sourceSize -> $releaseSize bytes.',
    );
    exitCode = 1;
    return;
  }

  final reduction = (1 - releaseSize / sourceSize) * 100;
  stdout.writeln(
    'Font subset verified: $sourceSize -> $releaseSize bytes '
    '(${reduction.toStringAsFixed(1)}% reduction).',
  );
}
