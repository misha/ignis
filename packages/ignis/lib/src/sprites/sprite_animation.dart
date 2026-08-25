// SPDX-AI-Disclosure: ai-assisted

import 'package:ignis/src/math.dart';
import 'package:ignis/src/sprite.dart';
import 'package:ignis/src/sprites/sprite_entry.dart';
import 'package:ignis/src/sprites/sprite_region.dart';

/// A run of frames, played.
///
/// The plain constructor is for art that ships a file per animation, where the
/// file is the whole of it:
///
/// ```dart
/// final idle = SpriteAnimation('assets/slime_idle.png', .all(56), fps: 16);
/// ```
///
/// This kind of sprite is frequently obtained via [SpriteSheet.animation],
/// which can cut up a single image into any number of animations.
class SpriteAnimation extends Sprite<int> {
  /// Which piece of which asset this plays.
  final SpriteRegion region;

  @override
  final List<SpriteEntry<int>> entries;

  /// Plays [region] at [fps], holding every frame for the same length of time.
  factory SpriteAnimation.of(
    SpriteRegion region, {
    required double fps,
    bool? loop,
  }) {
    if (fps < 0 || !fps.isFinite) {
      throw ArgumentError.value(
        fps,
        'fps',
        'Must be finite and non-negative.',
      );
    }

    final duration = fps <= 0 ? double.infinity : 1 / fps;

    return SpriteAnimation._(
      region,
      List.filled(region.frames, duration, growable: false),
      loop ?? true,
    );
  }

  /// Plays [region], holding each frame for its own number of seconds.
  factory SpriteAnimation.timedOf(
    SpriteRegion region,
    List<double> durations, {
    bool? loop,
  }) {
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

    return SpriteAnimation._(
      region,
      List.of(durations, growable: false),
      loop ?? true,
    );
  }

  /// Cuts the image cached at [asset] into [size] frames and plays them.
  factory SpriteAnimation(
    String asset,
    Vector2 size, {
    int? row,
    int? start,
    int? end,
    required double fps,
    bool? loop,
  }) {
    final region = SpriteRegion(asset, size, row: row, start: start, end: end);
    _checkWhole(region, row);
    return SpriteAnimation.of(region, fps: fps, loop: loop);
  }

  /// Cuts the image cached at [asset] into [size] frames, each held for its own
  /// number of seconds.
  factory SpriteAnimation.timed(
    String asset,
    Vector2 size,
    List<double> durations, {
    int? row,
    int? start,
    bool? loop,
  }) {
    final region = SpriteRegion(
      asset,
      size,
      row: row,
      start: start,
      end: (start ?? 0) + durations.length,
    );

    _checkWhole(region, row);
    return SpriteAnimation.timedOf(region, durations, loop: loop);
  }

  SpriteAnimation._(this.region, List<double> durations, bool loops)
    : entries = [
        SpriteEntry(
          index: 0,
          key: 0,
          image: region.image,
          size: region.cell,
          loops: loops,
          rects: region.cut(),
          durations: durations,
        ),
      ];

  /// Rejects a file cut into more rows than the one it was taken to hold.
  static void _checkWhole(SpriteRegion region, int? row) {
    if (row != null) return;
    final rows = region.rows;
    if (rows == 1) return;

    throw ArgumentError.value(
      region.cell,
      'size',
      'Cuts $rows rows out of this image. Name the row to play one of them.',
    );
  }

  @override
  SpriteEntry<int>? resolve(int key) {
    if (key != 0) return null;
    return entries.single;
  }

  @override
  Sprite<int> reload() {
    // Art evicted rather than replaced keeps whatever it last cut.
    if (!region.isLoaded) return this;
    final entry = entries.single;
    if (identical(region.image, entry.image)) return this;

    // Art replaced by something this region no longer sits inside keeps the
    // frames it last cut, rather than drawing outside the image.
    if (!region.fits) return this;

    return SpriteAnimation._(
      region,
      List.generate(
        region.frames,
        (frame) => entry.duration(frame < entry.frames ? frame : entry.frames - 1),
        growable: false,
      ),
      entry.loops,
    );
  }
}
