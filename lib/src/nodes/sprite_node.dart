import 'dart:ui';

import 'package:ignis/src/core.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/sized_node.dart';
import 'package:ignis/src/owners/speed_owner.dart';
import 'package:ignis/src/palette.dart';
import 'package:ignis/src/sprite.dart';
import 'package:ignis/src/sprites/sprite_entry.dart';
import 'package:ignis/src/sprites/sprite_key.dart';

/// What a [SpriteNode] is drawing.
final class SpriteState<T> {
  int _index = 0;
  T? _id;
  int _frame = 0;
  bool _loops = false;
  bool _finished = false;
  Vector2 _size = .zero;

  bool? _loop;
  double _elapsed = 0;
  Rect? _source;
  Rect? _destination;

  SpriteState._();

  /// Where the entry playing sits in the node's sprite.
  int get index => _index;

  /// What that entry answers to, or null where it goes unnamed.
  T? get id => _id;

  /// The frame drawn, counted from the start of the entry.
  int get frame => _frame;

  /// Whether the entry playing starts over after its final frame.
  bool get loops => _loops;

  /// Whether a non-looping entry has reached its final frame.
  bool get isFinished => _finished;

  /// The size of one frame of the entry playing.
  Vector2 get size => _size;

  /// Draws [frame] next, dropping the cut taken for the one before it.
  void _seek(int frame) {
    _frame = frame;
    _source = null;
  }

  /// Moves onto [frame] of [entry], reading [sprite] for everything else that
  /// follows from the move.
  void _select(Sprite<T> sprite, SpriteEntry<T> entry, int frame) {
    _index = entry.index;
    _id = entry.id;
    _frame = frame;
    _loops = _loop ?? sprite.loops(entry.index);
    _finished = false;
    _size = sprite.size(entry.index);
    _source = null;
    _destination = null;
  }

  @override
  String toString() {
    final buffer = StringBuffer('SpriteState(');
    buffer.write(_id == null ? 'entry $_index' : '$_id');
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
///     sprite: SpriteSheet('assets/fire.png', .new(32, 48), fps: 12),
///   ),
/// );
/// ```
///
/// A sprite takes its [size] from the frame, so [anchor], hit testing and
/// layout all work off the frame rather than the image. How fast it plays and
/// whether it loops belong to the sprite. [speed] scales the rate, and [play]
/// chooses which entry is playing.
class SpriteNode<T> extends SizedNode implements SpeedOwner {
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
  /// Ignored while while looping, since animation never finishes.
  bool cleanup;

  /// Emitted when animation advances to a new [SpriteState.frame].
  final onFrame = Signal1<int>();

  /// Emitted when a looping animation wraps to the start of its entry.
  final onLoop = Signal0();

  /// Emitted when a non-looping animation reaches its final frame.
  final onFinish = Signal0();

  final SpriteState<T> _current = SpriteState._();
  Sprite<T> _sprite;

  /// What this sprite draws.
  Sprite<T> get sprite => _sprite;

  /// The entry playing, the frame drawn, and everything else about it.
  SpriteState<T> get current => _current;

  /// The size of one frame of the entry currently playing.
  @override
  Vector2 get size => _current.size;

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
    _current._select(sprite, _resolve(const .index(0)), 0);
  }

  /// The entry [key] looks up, or a throw where [sprite] has none.
  ///
  /// The range check is here rather than in [Sprite.resolve], which takes an
  /// index it has already been vetted for.
  SpriteEntry<T> _resolve(SpriteKey<T> key) {
    if (key case SpriteIndex(:final index) when index < 0 || index >= _sprite.length) {
      throw ArgumentError.value(index, 'index', 'No such entry.');
    }

    final entry = _sprite.resolve(key);
    if (entry != null) return entry;

    throw ArgumentError.value(key, 'key', 'No such entry.');
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
        final duration = _sprite.duration(state.index, state.frame);

        if (duration <= 0 || !duration.isFinite) {
          state._elapsed = 0;
          return;
        }

        if (state._elapsed < duration) return;
        state._elapsed -= duration;
        final next = state.frame + 1;

        if (next < _sprite.frames(state.index)) {
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
        _sprite.image(state.index),
        state._source ??= _sprite.rect(state.index, state.frame),
        state._destination ??= .fromLTWH(0, 0, width, height),
        paint,
      );
    }

    draw((canvas) {
      palette.draw(canvas, painter);
    });

    debugDraw((canvas) {
      final debug = Ignis.debug;
      if (!debug.draws(.transforms)) return;
      canvas.drawRect(.fromLTWH(0, 0, width, height), debug.transformPaint);
    });
  }

  /// Re-resolves [sprite] through [Sprite.reload], so an image replaced in
  /// the cache reaches the screen without rebuilding this node.
  @override
  void reassemble() {
    _sprite = _sprite.reload();

    // Clamp the playhead if the replacement is smaller. An entry that went
    // away takes its frame with it.
    var index = _current.index;
    var frame = _current.frame;

    if (index >= _sprite.length) {
      index = 0;
      frame = 0;
    } else if (frame >= _sprite.frames(index)) {
      frame = 0;
    }

    _current._select(_sprite, _resolve(.index(index)), frame);
  }

  /// Plays the entry at [index] from the given [frame], or whichever entry
  /// [id] names.
  ///
  /// ```dart
  /// // Animates the third entry from its start.
  /// sprite.play(index: 2);
  ///
  /// // Animates whichever entry the sprite calls 'jump'.
  /// sprite.play(id: 'jump');
  /// ```
  ///
  /// [loop] overrides what the entry states, until the next call. It also
  /// clears [SpriteState.isFinished], so a non-looping sprite that already
  /// finished runs again from wherever this puts it.
  void play({
    T? id,
    int index = 0,
    int frame = 0,
    bool? loop,
  }) {
    assert(
      id == null || index == 0,
      'Must supply an id or an index, but not both.',
    );

    final entry = _resolve(id != null ? .id(id) : .index(index));

    if (frame < 0) {
      throw ArgumentError.value(
        frame,
        'frame',
        'Cannot be negative.',
      );
    }

    final frames = _sprite.frames(entry.index);

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
      .._select(_sprite, entry, frame);
  }
}
