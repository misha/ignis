import 'dart:ui';

import 'package:ignis/src/globals.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/sprite.dart';
import 'package:ignis/src/sprites/sprite_animation.dart';
import 'package:ignis/src/sprites/sprite_group.dart';
import 'package:ignis/src/sprites/sprite_image.dart';
import 'package:ignis/src/sprites/sprite_region.dart';

/// One row of a [SpriteSheet]'s grid, and how it plays.
///
/// ```dart
/// // Define a sprite sheet.
/// final sheet = SpriteSheet('assets/slime.png', .all(56));
///
/// // Cut out regions any way you like.
/// final group = sheet.animations(
///   fps: 16,
///   rows: [
///     .new(end: 14),
///     .new(end: 30, fps: 24, loop: false),
///     .skip(2),
///     .timed([0.8, 0.06, 0.06, 0.06]),
///   ],
/// );
/// ```
class SheetRow {
  /// The first column this row plays from. Defaults to 0.
  final int start;

  /// The column this row stops before, or null for the last one.
  final int? end;

  /// The frames per second this row plays at, or null for the rate the whole
  /// run was asked for.
  final double? fps;

  /// How long each frame is held, in seconds, or null to play at [fps].
  final List<double>? durations;

  /// Whether this row starts over after its last frame, or null for the
  /// answer the whole run was asked for.
  final bool? loop;

  /// How many rows of the grid the sheet passes over here, or null to play
  /// this one.
  final int? skip;

  const SheetRow({
    int? start,
    this.end,
    this.fps,
    this.loop,
  }) : assert(
         start == null || start >= 0,
         'A row starts at column 0 or later.',
       ),
       assert(
         end == null || end >= 1,
         'A row stops after column 1 or later.',
       ),
       assert(
         fps == null || (fps >= 0 && fps < double.infinity),
         'A rate is finite and not negative.',
       ),
       start = start ?? 0,
       durations = null,
       skip = null;

  /// A row that holds each of its frames for its own number of seconds.
  ///
  /// Plays as many frames as [durations] is long.
  SheetRow.timed(
    List<double> durations, {
    int? start,
    this.loop,
  }) : start = start ?? 0,
       end = (start ?? 0) + durations.length,
       fps = null,
       durations = .unmodifiable(durations),
       skip = null {
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

  /// The next [skip] rows of the grid, passed over rather than played.
  ///
  /// For grids that hold art this sheet has no use for. The rows declared
  /// after it carry on from where it leaves off.
  const SheetRow.skip(int skip)
    : assert(skip >= 1, 'A skip passes over at least one row.'),
      skip = skip,
      start = 0,
      end = null,
      fps = null,
      durations = null,
      loop = null;
}

/// A grid measured over an image, and the pieces you can take from it.
///
/// A sheet selects; it holds no animation properties of its own and nothing it
/// has worked out, so rows are coordinates you ask it about rather than things
/// it keeps.
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
/// ```dart
/// final sheet = SpriteSheet('assets/slime.png', .all(56));
///
/// sheet.image(row: 0, column: 3);
/// sheet.animation(row: 1, end: 30, fps: 24);
/// sheet.animations(fps: 16, rows: [.new(end: 14), .new(end: 30)]);
/// ```
class SpriteSheet {
  /// The cache key the grid is measured over.
  final String asset;

  /// The size of one frame.
  final Vector2 cell;

  /// Measures a grid of [cell] frames over the image cached at [asset].
  SpriteSheet(this.asset, Vector2 cell) : cell = .copy(cell);

  Image get _image => Ignis.cache.retrieve<Image>(asset);

  /// How many columns of frames the grid holds.
  int get columns => _image.width ~/ cell.x;

  /// How many rows of frames the grid holds.
  int get rows => _image.height ~/ cell.y;

  /// One frame of the grid, drawn still.
  ///
  /// For grids that hold art rather than animations, a tile map being the
  /// canonical example.
  SpriteImage image({
    int? row,
    int? column,
  }) {
    row ??= 0;
    column ??= 0;

    return SpriteImage.of(
      SpriteRegion(
        asset,
        cell,
        row: row,
        start: column,
        end: column + 1,
      ),
    );
  }

  /// One row of the grid, or a span of one, played at [fps].
  SpriteAnimation animation({
    int? row,
    int? start,
    int? end,
    required double fps,
    bool? loop,
  }) {
    return SpriteAnimation(
      asset,
      cell,
      row: row ?? 0,
      start: start,
      end: end,
      fps: fps,
      loop: loop,
    );
  }

  /// One row of the grid, holding each frame for its own number of seconds.
  SpriteAnimation timed(
    List<double> durations, {
    int? row,
    int? start,
    bool? loop,
  }) {
    return SpriteAnimation.timed(
      asset,
      cell,
      durations,
      row: row ?? 0,
      start: start,
      loop: loop,
    );
  }

  /// Every row of the grid, played as [rows] says, end to end.
  ///
  /// Rows are stated in the order the grid holds them. A [SheetRow.skip] passes
  /// over as many as it counts, and a row left unstated plays whole at [fps].
  SpriteGroup animations({
    required double fps,
    bool? loop,
    List<SheetRow>? rows,
  }) {
    final grid = this.rows;
    final declared = rows ?? const <SheetRow>[];
    final animations = <Sprite<int>>[];
    var index = 0;
    var row = 0;

    while (row < grid) {
      SheetRow? stated;

      while (index < declared.length) {
        final next = declared[index];
        index += 1;
        final skip = next.skip;

        if (skip == null) {
          stated = next;
          break;
        }

        row += skip;

        if (row > grid) {
          throw ArgumentError.value(
            skip,
            'rows[${index - 1}]',
            'Skips past row $grid, from row ${row - skip}.',
          );
        }
      }

      if (row >= grid) break;

      final durations = stated?.durations;

      if (durations == null) {
        animations.add(
          animation(
            row: row,
            start: stated?.start,
            end: stated?.end,
            fps: stated?.fps ?? fps,
            loop: stated?.loop ?? loop,
          ),
        );
      } else {
        animations.add(
          timed(
            durations,
            row: row,
            start: stated?.start,
            loop: stated?.loop ?? loop,
          ),
        );
      }

      row += 1;
    }

    if (index < declared.length) {
      throw ArgumentError.value(
        declared.length,
        'rows',
        'The sheet only has $grid rows.',
      );
    }

    if (animations.isEmpty) {
      throw ArgumentError.value(rows, 'rows', 'Every row is skipped.');
    }

    return SpriteGroup(animations);
  }
}
