import 'dart:ui';

import 'package:ignis/src/math.dart';
import 'package:ignis/src/sprite.dart';

/// One entry of a [Sprite]: the frames it draws, and how it plays them.
///
/// A sprite answers with one of these rather than a field at a time, so an
/// implementation states what it holds instead of inventing a storage unit to
/// answer from. Frames are cut once, here, rather than on every draw.
final class SpriteEntry<T> {
  /// Where this sits in the sprite that holds it.
  final int index;

  /// What this answers to.
  ///
  /// Art numbers its entries, so this is [index] again where nothing named it.
  final T key;

  /// The image this is drawn from.
  final Image image;

  /// The size of one frame, which a sprite node takes as its shape.
  final Vector2 size;

  /// Whether this starts over after its last frame.
  final bool loops;

  final List<Rect> _rects;
  final List<double> _durations;

  /// How many frames this plays.
  int get frames => _rects.length;

  SpriteEntry({
    required this.index,
    required this.key,
    required this.image,
    required this.size,
    required this.loops,
    required List<Rect> rects,
    required List<double> durations,
  }) : assert(
         rects.length == durations.length,
         'An entry holds a duration for every frame.',
       ),
       _rects = rects,
       _durations = durations;

  /// Where [frame] sits in [image].
  Rect rect(int frame) => _rects[frame];

  /// How long [frame] is held, in seconds.
  ///
  /// Infinite where the frame is never left.
  double duration(int frame) => _durations[frame];

  /// The same entry, sitting at [index] and answering to [key] instead.
  ///
  /// For the layers that renumber or name what they hold.
  SpriteEntry<U> rename<U>(int index, U key) {
    return SpriteEntry<U>(
      index: index,
      key: key,
      image: image,
      size: size,
      loops: loops,
      rects: _rects,
      durations: _durations,
    );
  }

  @override
  String toString() => 'SpriteEntry($key, $frames frames)';
}
