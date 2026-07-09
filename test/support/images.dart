import 'dart:typed_data';
import 'dart:ui';

import 'package:ignis/ignis.dart';

import 'colors.dart';

/// Renders a [width]x[height] image with the given, solid [color].
Future<Image> solidImage(int width, int height, [Color color = WHITE]) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);

  canvas.drawRect(
    Rect.fromLTWH(0, 0, width.toDouble(), height.toDouble()),
    Paint()..color = color,
  );

  return recorder.endRecording().toImage(width, height);
}

/// Renders a 1x1 color grid image by interpreting [colors] as the color map.
Future<Image> pixelImage(List<List<Color>> colors) {
  final recorder = PictureRecorder();
  final canvas = Canvas(recorder);

  for (final (row, colors) in colors.indexed) {
    for (final (column, color) in colors.indexed) {
      canvas.drawRect(
        Rect.fromLTWH(column.toDouble(), row.toDouble(), 1, 1),
        Paint()..color = color,
      );
    }
  }

  return recorder.endRecording().toImage(colors.first.length, colors.length);
}

/// Renders [node] to a [width]x[height] image.
Future<Image> renderImage(Node node, int width, int height) {
  final recorder = PictureRecorder();
  node.render(Canvas(recorder));
  return recorder.endRecording().toImage(width, height);
}

/// Reads the raw ARGB pixels of [image], row by row.
Future<Uint32List> pixelsOf(Image image) async {
  final data = await image.toByteData();
  return data!.buffer.asUint32List();
}

/// Reads the color of the pixel at ([x], [y]) in [image].
Future<Color> pixelAt(Image image, int x, int y) async {
  final data = await image.toByteData();
  final bytes = data!.buffer.asUint8List();
  final offset = (y * image.width + x) * 4;

  return Color.fromARGB(
    bytes[offset + 3],
    bytes[offset],
    bytes[offset + 1],
    bytes[offset + 2],
  );
}
