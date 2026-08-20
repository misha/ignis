import 'dart:ui';

import 'package:ignis/src/core.dart';
import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/owners/speed_owner.dart';
import 'package:ignis/src/palette.dart';
import 'package:ignis/src/shape.dart';
import 'package:ignis/src/sprite.dart';
import 'package:ignis/src/sprites/sprite_entry.dart';

/// What a [SpriteNode] is drawing.
final class SpriteState<T> {
  late SpriteEntry<T> _entry;
  late Shape _shape;
  int _frame = 0;
  bool _loops = false;
  bool _finished = false;

  bool? _loop;
  double _elapsed = 0;
  Rect? _source;
  Rect? _destination;

  SpriteState._();

  /// Where the entry playing sits in the node's sprite.
  int get index => _entry.index;

  /// What that entry answers to.
  T get key => _entry.key;

  /// The frame drawn, counted from the start of the entry.
  int get frame => _frame;

  /// Whether the entry playing starts over after its final frame.
  bool get loops => _loops;

  /// Whether a non-looping entry has reached its final frame.
  bool get isFinished => _finished;

  /// One frame of the entry playing, as a rectangle.
  Shape get shape => _shape;

  /// Draws [frame] next, dropping the cut taken for the one before it.
  void _seek(int frame) {
    _frame = frame;
    _source = null;
  }

  /// Moves onto [frame] of [entry].
  void _select(SpriteEntry<T> entry, int frame) {
    _entry = entry;
    _shape = Rectangle(entry.size);
    _frame = frame;
    _loops = _loop ?? entry.loops;
    _finished = false;
    _source = null;
    _destination = null;
  }

  @override
  String toString() {
    final buffer = StringBuffer('SpriteState(${_entry.key}');
    if (_finished) buffer.write(', finished');
    buffer.write(')');
    return buffer.toString();
  }
}

/// Draws one frame of a [Sprite] at a time, and animates along its entry.
///
/// ```dart
/// add(
///   SpriteNode(
///     sprite: SpriteAnimation('assets/fire.png', .new(32, 48), fps: 12),
///   ),
/// );
/// ```
///
/// A sprite takes its [shape] from the frame, so [anchor], hit testing and
/// layout all work off the frame rather than the image. How fast it plays and
/// whether it loops belong to the sprite. [speed] scales the rate, and [play]
/// chooses which entry is playing.
class SpriteNode<T> extends SpatialNode implements SpeedOwner {
  final SpriteState<T> _current = SpriteState._();
  Sprite<T> _sprite;

  /// What this sprite draws.
  Sprite<T> get sprite => _sprite;

  /// The entry playing, the frame drawn, and everything else about it.
  SpriteState<T> get current => _current;

  /// One frame of the entry currently playing, as a rectangle.
  @override
  Shape get shape => _current.shape;

  /// This node's registered paints.
  final Palette palette;

  /// The default paint.
  Paint get paint => palette.paint;

  /// How fast this sprite plays, as a multiple of the rate its [sprite] states.
  ///
  /// Defaults to 1. Must be >= 0, where 0 holds the current frame.
  @override
  double speed;

  /// Whether to [detach] once finished. Defaults to false.
  ///
  /// Ignored while looping, since animation never finishes.
  bool cleanup;

  /// Emitted when animation advances to a new [SpriteState.frame].
  final onFrame = Signal1<int>();

  /// Emitted when a looping animation wraps to the start of its entry.
  final onLoop = Signal0();

  /// Emitted when a non-looping animation reaches its final frame.
  final onFinish = Signal0();

  /// Creates a node that draws [sprite].
  SpriteNode({
    required this._sprite,
    Paint? paint,
    double? speed,
    bool? cleanup,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : assert(speed == null || speed >= 0, 'Speed cannot be negative.'),
       palette = Palette(paint: paint),
       speed = speed ?? 1,
       cleanup = cleanup ?? false {
    _current._select(sprite.entries.first, 0);
  }

  @override
  void build() {
    super.build();

    tick((dt) {
      final state = _current;
      if (state.isFinished) return;
      final amount = dt * speed;
      if (amount <= 0 || !amount.isFinite) return;

      state._elapsed += amount;

      // Every pass re-reads the state, so a handler calling play() redirects
      // this loop instead of racing it.
      while (true) {
        final duration = state._entry.duration(state.frame);

        if (duration <= 0 || !duration.isFinite) {
          state._elapsed = 0;
          return;
        }

        if (state._elapsed < duration) return;
        state._elapsed -= duration;
        final next = state.frame + 1;

        if (next < state._entry.frames) {
          state._seek(next);
          onFrame.emit(next);
        } else if (state.loops) {
          state._seek(0);
          onFrame.emit(0);
          onLoop.emit();
        } else {
          state._elapsed = 0;
          state._finished = true;
          onFinish.emit();

          if (cleanup) {
            detach();
          }

          return;
        }
      }
    });

    void painter(Canvas canvas, Paint paint) {
      final state = _current;

      canvas.drawImageRect(
        state._entry.image,
        state._source ??= state._entry.rect(state.frame),
        state._destination ??= .fromLTWH(0, 0, width, height),
        paint,
      );
    }

    draw((canvas) {
      palette.draw(canvas, painter);
    });
  }

  /// Re-resolves [sprite] through [Sprite.reload], so an image replaced in
  /// the cache reaches the screen without rebuilding this node.
  @override
  void reassemble() {
    _sprite = _sprite.reload();

    // Follow the entry by name. An entry the replacement dropped takes its
    // frame with it, and one that grew shorter starts over.
    final entry = _sprite.resolve(_current.key);

    if (entry == null) {
      _current._select(_sprite.entries.first, 0);
      return;
    }

    final frame = _current.frame;
    _current._select(entry, frame < entry.frames ? frame : 0);
  }

  /// Plays the entry [key] names, from the given [frame].
  ///
  /// ```dart
  /// // Animates the third entry of a sheet from its start.
  /// sprite.play(2);
  ///
  /// // Animates whichever entry a map calls 'jump'.
  /// sprite.play('jump');
  /// ```
  ///
  /// [loop] overrides what the entry states, until the next call. It also
  /// clears [SpriteState.isFinished], so a non-looping sprite that already
  /// finished runs again from wherever this puts it.
  void play(
    T key, {
    int frame = 0,
    bool? loop,
  }) {
    final entry = _sprite.resolve(key);

    if (entry == null) {
      throw ArgumentError.value(key, 'key', 'No such entry.');
    }

    if (frame < 0) {
      throw ArgumentError.value(
        frame,
        'frame',
        'Cannot be negative.',
      );
    }

    final frames = entry.frames;

    if (frame >= frames) {
      throw ArgumentError.value(
        frame,
        'frame',
        'That entry only plays $frames frames.',
      );
    }

    _current
      .._loop = loop
      .._elapsed = 0
      .._select(entry, frame);
  }

  /// Plays the entry after the one playing, wrapping past the last.
  void playNext() {
    final entries = _sprite.entries;
    play(entries[(_current.index + 1) % entries.length].key);
  }

  /// Plays the entry before the one playing, wrapping past the first.
  void playPrevious() {
    final entries = _sprite.entries;
    play(entries[(_current.index - 1) % entries.length].key);
  }
}
