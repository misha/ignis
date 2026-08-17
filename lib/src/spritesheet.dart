import 'dart:ui';

import 'package:ignis/src/assets/cache.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/math.dart';

/// The cache entry a [Spritesheet] was derived from.
final class SpritesheetSource {
  /// The key of the image in the cache.
  final String asset;

  /// The frame size originally requested, or null for the image's own size.
  final Vector2? size;

  const SpritesheetSource(this.asset, this.size);
}

/// An image cut into a grid of equally sized frames.
///
/// Frames are numbered row-major from the top left, and a [SpriteNode] animates
/// along one row:
///
/// ```
/// +---+---+---+---+
/// | 0 | 1 | 2 | 3 |
/// +---+---+---+---+
/// | 4 | 5 | 6 | 7 |
/// +---+---+---+---+
/// ```
///
/// ```dart
/// final sheet = Spritesheet.asset('assets/fire.png', size: .new(32, 48));
/// ```
class Spritesheet {
  /// The image the frames are cut from.
  final Image image;

  /// The size of a single frame.
  late final Vector2 size;

  late final int rows;
  late final int columns;

  /// How many frames the grid holds, across every row.
  late final int frames;

  /// Where this sheet came from, or null when built from an image directly.
  final SpritesheetSource? source;

  late final List<Rect> _rects;

  /// Cuts the image cached at [key] into frames of the given [size].
  ///
  /// The sheet itself is cached under a key derived from [key] and the frame
  /// size, so replacing the image evicts every sheet cut out of it.
  factory Spritesheet.asset(
    String key, {
    Vector2? size,
  }) {
    final cache = Ignis.cache;
    final image = cache.retrieve<Image>(key);
    final frame = size ?? Vector2.cast(image.width, image.height);
    final derived = Cache.derive(key, '${frame.x},${frame.y}');
    if (cache.contains(derived)) return cache.retrieve<Spritesheet>(derived);

    final sheet = Spritesheet(
      image,
      size: frame,
      source: .new(key, size),
    );

    cache.add(derived, sheet);
    return sheet;
  }

  Spritesheet(
    this.image, {
    Vector2? size,
    this.source,
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

  /// This sheet, re-resolved against [Ignis.cache].
  ///
  /// Returns this unless the image it was cut from has since been replaced.
  Spritesheet get current {
    final source = this.source;
    if (source == null) return this;
    final image = Ignis.cache.retrieve<Image>(source.asset);
    if (identical(image, this.image)) return this;
    return Spritesheet.asset(source.asset, size: source.size);
  }
}
