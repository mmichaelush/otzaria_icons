import 'package:flutter/material.dart';

import 'generated/icon_catalog.dart';

void main() => runApp(const IconGalleryApp());

class IconGalleryApp extends StatefulWidget {
  const IconGalleryApp({super.key});

  @override
  State<IconGalleryApp> createState() => _IconGalleryAppState();
}

class _IconGalleryAppState extends State<IconGalleryApp> {
  ThemeMode _themeMode = ThemeMode.light;
  TextDirection _direction = TextDirection.ltr;
  double _size = 24;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      themeMode: _themeMode,
      theme: ThemeData(colorSchemeSeed: Colors.indigo),
      darkTheme: ThemeData(
        colorSchemeSeed: Colors.indigo,
        brightness: Brightness.dark,
      ),
      home: Directionality(
        textDirection: _direction,
        child: Scaffold(
          appBar: AppBar(
            title: const Text('Otzaria Icons'),
            actions: [
              IconButton(
                tooltip: 'Toggle direction',
                onPressed: () => setState(() {
                  _direction = _direction == TextDirection.ltr
                      ? TextDirection.rtl
                      : TextDirection.ltr;
                }),
                icon: const Icon(Icons.format_textdirection_r_to_l),
              ),
              IconButton(
                tooltip: 'Toggle theme',
                onPressed: () => setState(() {
                  _themeMode = _themeMode == ThemeMode.light
                      ? ThemeMode.dark
                      : ThemeMode.light;
                }),
                icon: const Icon(Icons.contrast),
              ),
            ],
          ),
          body: Column(
            children: [
              Slider(
                min: 16,
                max: 48,
                divisions: 4,
                label: '${_size.round()} px',
                value: _size,
                onChanged: (value) => setState(() => _size = value),
              ),
              Expanded(
                child: GridView.extent(
                  maxCrossAxisExtent: 260,
                  padding: const EdgeInsets.all(16),
                  children: [
                    for (final icon in iconCatalog)
                      _IconCard(
                        name: icon.name,
                        icon: icon.data,
                        size: _size,
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconCard extends StatelessWidget {
  const _IconCard({
    required this.name,
    required this.icon,
    required this.size,
  });

  final String name;
  final IconData icon;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, size: size),
            const SizedBox(height: 16),
            SelectableText(name, textAlign: TextAlign.center),
            Text('U+${icon.codePoint.toRadixString(16).toUpperCase()}'),
          ],
        ),
      ),
    );
  }
}
