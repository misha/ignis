import 'dart:ui';

import 'package:ignis/src/globals.dart';
import 'package:ignis/src/math.dart';

// TODO: Document usage and properties.
class Spritesheet {
  static final Map<(String, double?, double?), Spritesheet> _cache = {};
  static void clearCache() => _cache.clear();

  final Image image;
  late final Vector2 size;
  late final int rows;
  late final int columns;
  late final int frames;

  late final List<Rect> _rects;

  factory Spritesheet.asset(
    String key, {
    Vector2? size,
  }) {
    return _cache.putIfAbsent((key, size?.x, size?.y), () {
      return Spritesheet(Ignis.cache.retrieve(key), size: size);
    });
  }

  Spritesheet(
    this.image, {
    Vector2? size,
  }) {
    this.size = (size ?? .cast(image.width, image.height)).clone();
    final width = this.size.x;
    final height = this.size.y;

    if (width <= 0 || !width.isFinite) {
      throw ArgumentError.value(
        width,
        'size.x',
        'Must be positive and finite.',
      );
    }

    if (height <= 0 || !height.isFinite) {
      throw ArgumentError.value(
        height,
        'size.y',
        'Must be positive and finite.',
      );
    }

    if (image.width % width != 0) {
      throw ArgumentError.value(
        width,
        'size.x',
        'Must divide the image width evenly.',
      );
    }

    if (image.height % height != 0) {
      throw ArgumentError.value(
        height,
        'size.y',
        'Must divide the image height evenly.',
      );
    }

    columns = image.width ~/ width;
    rows = image.height ~/ height;
    frames = rows * columns;

    _rects = List.generate(
      frames,
      (frame) {
        final row = frame ~/ columns;
        final column = frame % columns;

        return Rect.fromLTWH(
          column * width,
          row * height,
          width,
          height,
        );
      },
      growable: false,
    );
  }

  Rect operator [](int frame) => _rects[frame];
}
