// SPDX-AI-Disclosure: ai-assisted

import 'dart:ui';

import 'package:ignis/src/globals.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/sprites/sprite_entry.dart';

/// Which piece of which asset a sprite draws.
///
/// A region states where its frames sit rather than holding the cuts, so it
/// answers against whatever the cache holds now. What it describes is cut once,
/// into a [SpriteEntry], and cut again only when the image behind it changes.
///
/// ```dart
/// SpriteRegion('assets/slime.png', .all(56), row: 3, end: 12);
/// ```
final class SpriteRegion {
  /// The cache key the frames are cut from.
  final String asset;

  final Vector2? _cell;

  /// The row of the grid the frames sit on.
  final int row;

  /// The first column played, counted from the start of the row.
  final int start;

  /// The column played up to, or null to run to the end of the row.
  ///
  /// A region left open re-reads the width of a replacement image, so art that
  /// grows a frame plays it without being redeclared.
  final int? end;

  /// Describes a piece of the image cached at [asset], cut into [cell] frames.
  factory SpriteRegion(
    String asset,
    Vector2 cell, {
    int? row,
    int? start,
    int? end,
  }) {
    row ??= 0;
    start ??= 0;
    final region = SpriteRegion._(asset, .copy(cell), row, start, end);
    region._validate();
    return region;
  }

  /// Describes the whole of the image cached at [asset], as one frame.
  ///
  /// Stating no frame size measures the region against the image rather than
  /// over it, so it re-measures when the art behind it changes shape.
  const SpriteRegion.whole(this.asset) //
    : _cell = null,
      row = 0,
      start = 0,
      end = 1;

  const SpriteRegion._(
    this.asset,
    this._cell,
    this.row,
    this.start,
    this.end,
  );

  /// Whether the cache still holds the art this is cut from.
  ///
  /// TODO: Consider a different name.
  bool get isLoaded => Ignis.cache.contains(asset);

  /// The image this is cut from, as the cache holds it now.
  Image get image => Ignis.cache.retrieve<Image>(asset);

  /// The size of one frame, which is the whole image where none was stated.
  Vector2 get cell => _cell ?? Vector2.cast(image.width, image.height);

  /// How many columns of frames the image holds.
  int get columns => image.width ~/ cell.x;

  /// How many rows of frames the image holds.
  int get rows => image.height ~/ cell.y;

  /// How many frames this plays.
  int get frames => (end ?? columns) - start;

  /// Whether the image the cache holds now still holds this region.
  bool get fits {
    final image = this.image;
    final cell = this.cell;

    if (image.width % cell.x != 0 || image.height % cell.y != 0) return false;
    if (row >= image.height ~/ cell.y) return false;

    final columns = image.width ~/ cell.x;
    return (end ?? columns) <= columns;
  }

  /// One [Rect] per frame, against the image the cache holds now.
  List<Rect> cut() {
    final cell = this.cell;
    final width = cell.x;
    final height = cell.y;
    final top = row * height;

    return List.generate(
      frames,
      (frame) => Rect.fromLTWH(
        (start + frame) * width,
        top,
        width,
        height,
      ),
      growable: false,
    );
  }

  void _validate() {
    final cell = this.cell;
    final width = cell.x;
    final height = cell.y;

    if (width <= 0 || !width.isFinite) {
      throw ArgumentError.value(
        width,
        'cell.x',
        'Must be positive and finite.',
      );
    }

    if (height <= 0 || !height.isFinite) {
      throw ArgumentError.value(
        height,
        'cell.y',
        'Must be positive and finite.',
      );
    }

    final image = this.image;

    if (image.width % width != 0) {
      throw ArgumentError.value(
        width,
        'cell.x',
        'Must divide the image width evenly.',
      );
    }

    if (image.height % height != 0) {
      throw ArgumentError.value(
        height,
        'cell.y',
        'Must divide the image height evenly.',
      );
    }

    final rows = this.rows;

    if (row < 0 || row >= rows) {
      throw ArgumentError.value(
        row,
        'row',
        'The image only has $rows rows.',
      );
    }

    final columns = this.columns;

    if (start < 0 || start >= columns) {
      throw ArgumentError.value(
        start,
        'start',
        'The image only has $columns columns.',
      );
    }

    final end = this.end;
    if (end == null) return;

    if (end <= start) {
      throw ArgumentError.value(
        end,
        'end',
        'Must run past column $start.',
      );
    }

    if (end > columns) {
      throw ArgumentError.value(
        end,
        'end',
        'Runs past column $columns, on a row of $columns.',
      );
    }
  }

  @override
  String toString() => 'SpriteRegion($asset, row $row, $start..${end ?? columns})';
}
