import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:xml/xml.dart';

const _sourceDirectory = 'assets_src/svg';
const _safeWrapperAttributes = {'fill', 'fill-rule', 'clip-rule'};

void main(List<String> arguments) {
  final directory = Directory(_sourceDirectory);
  if (!directory.existsSync()) {
    stderr.writeln('ERROR: Missing source directory: $_sourceDirectory');
    exitCode = 1;
    return;
  }

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
    final elementChildren = svg.childElements.toList();
    if (elementChildren.length != 1) continue;

    final wrapper = elementChildren.single;
    if (wrapper.name.local != 'g') continue;
    if (wrapper.attributes.any(
      (attribute) => !_safeWrapperAttributes.contains(attribute.name.local),
    )) {
      continue;
    }
    if (wrapper.descendants.whereType<XmlElement>().any(
          (element) => element.name.local == 'g',
        )) {
      continue;
    }

    for (final attribute in wrapper.attributes) {
      if (svg.getAttribute(attribute.name.local) == null) {
        svg.setAttribute(attribute.name.local, attribute.value);
      }
    }
    final wrapperIndex = svg.children.indexOf(wrapper);
    svg.children.replaceRange(
      wrapperIndex,
      wrapperIndex + 1,
      wrapper.children.map((child) => child.copy()),
    );
    file.writeAsStringSync('${document.toXmlString()}\n');
    stdout.writeln('Flattened safe wrapper group: ${p.basename(file.path)}');
    changed++;
  }

  stdout.writeln('Sanitized ${files.length} SVG file(s); changed $changed.');
}
