import 'dart:ui';

import 'package:ignis/src/globals.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/sprite.dart';

// TODO: Sprite sheets should precache their computed rects rather than create
//  them on demand.

/// One row of a [SpriteSheet]'s grid, and how it plays.
///
/// ```dart
/// SpriteSheet('assets/slime.png', .all(56), fps: 16, rows: [
///   .new(key: 'idle', frames: 14),
///   .new(key: 'jump', frames: 30, fps: 24, loop: false),
/// ]);
/// ```
class SheetRow<T> {
  /// What this row answers to in [Sprite.rowOf], or null to go unnamed.
  final T? key;

  /// The first column this row plays from. Defaults to 0.
  final int start;

  /// How many frames this row plays, or null for every column after [start].
  final int? frames;

  /// The frames per second this row plays at, or null for the sheet's rate.
  final double? fps;

  /// How long each frame is held, in seconds, or null to play at [fps].
  final List<double>? durations;

  /// Whether this row starts over after its last frame, or null for the
  /// sheet's answer.
  final bool? loop;

  const SheetRow({
    this.key,
    int? start,
    this.frames,
    this.fps,
    this.loop,
  }) : assert(start == null || start >= 0, 'A row starts at column 0 or later.'),
       assert(frames == null || frames >= 1, 'A row plays at least one frame.'),
       assert(
         fps == null || (fps >= 0 && fps < double.infinity),
         'A rate is finite and not negative.',
       ),
       start = start ?? 0,
       durations = null;

  /// A row that holds each of its frames for its own number of seconds.
  ///
  /// Plays as many frames as [durations] is long.
  SheetRow.timed(
    List<double> durations, {
    this.key,
    int? start,
    this.loop,
  }) : start = start ?? 0,
       frames = null,
       fps = null,
       durations = .unmodifiable(durations) {
    if (durations.isEmpty) {
      throw ArgumentError.value(
        durations,
        'durations',
        'Must hold at least one frame.',
      );
    }

    for (var index = 0; index < durations.length; index += 1) {
      final duration = durations[index];

      if (duration <= 0 || !duration.isFinite) {
        throw ArgumentError.value(
          duration,
          'durations[$index]',
          'Must be positive and finite.',
        );
      }
    }
  }
}

/// One row of a sheet, resolved against the sheet that holds it.
final class _Row {
  final int start;
  final int frames;
  final double duration;
  final List<double>? durations;
  final bool loop;

  const _Row(
    this.start,
    this.frames,
    this.duration,
    this.durations,
    this.loop,
  );
}

/// An image cut into a grid of equally sized frames.
///
/// Frames are numbered from the start of their row, and a [SpriteNode] animates
/// along one row. A 128x64 image with a 32x32 [size] holds two rows of four:
///
/// ```
///     0              128
///   0 +---+---+---+---+
///     | 0 | 1 | 2 | 3 |
///     +---+---+---+---+
///     | 0 | 1 | 2 | 3 |
///  64 +---+---+---+---+
/// ```
///
/// A row plays its whole width at the sheet's [fps] unless a [SheetRow] says
/// otherwise:
///
/// ```dart
/// final sheet = SpriteSheet('assets/fire.png', .new(32, 48), fps: 12);
/// ```
class SpriteSheet<T> extends Sprite<T> {
  /// The rate every row without an [SheetRow.fps] of its own plays at.
  ///
  /// A rate of 0 holds a row on its first frame, which is what a sheet whose
  /// rows all time themselves states.
  final num fps;

  /// Whether every row without a [SheetRow.loop] of its own starts over.
  final bool loop;

  /// The cache key this sheet was cut from.
  final String asset;

  @override
  late final int rows;

  /// How many columns of frames the grid holds.
  late final int columns;

  final Image _image;
  final Vector2 _size;
  final List<SheetRow<T>>? _declared;
  late final List<_Row> _rows;

  /// Cuts the image cached at [asset] into frames of the given [size].
  factory SpriteSheet(
    String asset,
    Vector2 size, {
    required num fps,
    bool? loop,
    List<SheetRow<T>>? rows,
  }) {
    final image = Ignis.cache.retrieve<Image>(asset);
    return SpriteSheet._(image, size, asset, fps, loop, rows);
  }

  /// Cuts an image that holds one animation, under the name [key].
  ///
  /// For art that ships a file per animation, where the row is the whole sheet
  /// and there is nothing to number.
  factory SpriteSheet.single(
    String asset,
    Vector2 size, {
    required num fps,
    T? key,
    bool? loop,
  }) {
    final sheet = SpriteSheet<T>(
      asset,
      size,
      fps: fps,
      loop: loop,
      rows: [SheetRow<T>(key: key)],
    );

    if (sheet.rows != 1) {
      throw ArgumentError.value(
        size,
        'size',
        'Cuts ${sheet.rows} rows out of this image, not one.',
      );
    }

    return sheet;
  }

  SpriteSheet._(
    this._image,
    Vector2 size,
    this.asset,
    this.fps,
    bool? loop,
    List<SheetRow<T>>? declared,
  ) : assert(fps >= 0 && fps < double.infinity, 'FPS must be finite and non-negative.'),
      _size = .copy(size),
      loop = loop ?? true,
      _declared = declared == null ? null : List.of(declared, growable: false) {
    final width = _size.x;
    final height = _size.y;

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

    if (_image.width % width != 0) {
      throw ArgumentError.value(
        width,
        'size.x',
        'Must divide the image width evenly.',
      );
    }

    if (_image.height % height != 0) {
      throw ArgumentError.value(
        height,
        'size.y',
        'Must divide the image height evenly.',
      );
    }

    columns = _image.width ~/ width;
    rows = _image.height ~/ height;

    final declared = _declared;

    if (declared != null && declared.length > rows) {
      throw ArgumentError.value(
        declared.length,
        'rows',
        'The sheet only has $rows rows.',
      );
    }

    _rows = .generate(rows, _resolve, growable: false);
  }

  /// The row at [index], with everything it left unstated filled in.
  _Row _resolve(int index) {
    final declared = _declared;
    final row = declared == null || index >= declared.length ? null : declared[index];
    final start = row?.start ?? 0;

    if (start >= columns) {
      throw ArgumentError.value(
        start,
        'rows[$index].start',
        'The sheet only has $columns columns.',
      );
    }

    final durations = row?.durations;
    final frames = durations?.length ?? row?.frames ?? columns - start;

    if (frames < 1) {
      throw ArgumentError.value(
        frames,
        'rows[$index].frames',
        'Must be at least 1.',
      );
    }

    if (start + frames > columns) {
      throw ArgumentError.value(
        frames,
        'rows[$index].frames',
        'Runs past column $columns, starting at $start.',
      );
    }

    final rate = row?.fps ?? fps;

    return _Row(
      start,
      frames,
      rate <= 0 ? double.infinity : 1 / rate,
      durations,
      row?.loop ?? loop,
    );
  }

  @override
  int? rowOf(T key) {
    final declared = _declared;
    if (declared == null) return null;

    for (var index = 0; index < declared.length; index += 1) {
      if (declared[index].key == key) return index;
    }

    return null;
  }

  @override
  Image image(int row) => _image;

  @override
  Vector2 size(int row) => _size;

  @override
  int frames(int row) => _rows[row].frames;

  @override
  bool loops(int row) => _rows[row].loop;

  @override
  Rect rect(int row, int index) {
    final resolved = _rows[row];
    _checkFrame(index, resolved);
    final width = _size.x;
    final height = _size.y;

    return .fromLTWH(
      (resolved.start + index) * width,
      row * height,
      width,
      height,
    );
  }

  @override
  double duration(int row, int index) {
    final resolved = _rows[row];
    _checkFrame(index, resolved);
    return resolved.durations?[index] ?? resolved.duration;
  }

  void _checkFrame(int index, _Row row) {
    if (index < 0 || index >= row.frames) {
      throw RangeError.index(index, this, 'index', null, row.frames);
    }
  }

  @override
  SpriteSheet<T> reload() {
    final image = Ignis.cache.retrieve<Image>(asset);
    if (identical(image, _image)) return this;
    return SpriteSheet._(image, _size, asset, fps, loop, _declared);
  }
}
