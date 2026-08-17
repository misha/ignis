import 'dart:ui';

import 'package:ignis/src/core.dart';
import 'package:ignis/src/debug.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/sized_node.dart';
import 'package:ignis/src/owners/speed_owner.dart';
import 'package:ignis/src/palette.dart';
import 'package:ignis/src/sprite.dart';

/// Draws one frame of a [Sprite] at a time, and animates along its row.
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
/// chooses which row is playing.
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
  /// Ignored while [loops] is true, since a looping sprite never finishes.
  bool cleanup;

  /// Emitted when animation advances to a new [frame].
  final onFrame = Signal1<int>();

  /// Emitted when a looping animation wraps to the start of its row.
  final onLoop = Signal0();

  /// Emitted when a non-looping animation reaches its final frame.
  final onFinish = Signal0();

  Sprite<T> _sprite;
  int _row = 0;
  int _frame = 0;
  double _elapsed = 0;
  bool? _loop;
  bool _finished = false;

  Rect? _source;
  Rect? _destination;

  /// What this sprite draws.
  Sprite<T> get sprite => _sprite;

  /// The row currently playing, indexed into [sprite].
  int get row => _row;

  /// The frame currently drawn, counted from the start of [row].
  int get frame => _frame;

  /// Whether the row currently playing starts over after its final frame.
  bool get loops => _loop ?? _sprite.loops(_row);

  /// Whether a non-looping animation has reached its final frame.
  bool get isFinished => _finished;

  /// The size of one frame of the row currently playing.
  @override
  Vector2 get size => _sprite.size(_row);

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
       cleanup = cleanup ?? false;

  @override
  void build() {
    super.build();

    tick((dt) {
      if (_finished) return;
      final amount = dt * speed;
      if (amount <= 0 || !amount.isFinite) return;

      _elapsed += amount;

      // Every pass re-reads the fields, so a handler calling play() redirects
      // this loop instead of racing it.
      while (true) {
        final duration = _sprite.duration(_row, _frame);

        if (duration <= 0 || !duration.isFinite) {
          _elapsed = 0;
          return;
        }

        if (_elapsed < duration) return;
        _elapsed -= duration;
        final next = _frame + 1;

        if (next < _sprite.frames(_row)) {
          _frame = next;
          _source = null;
          onFrame.emit(next);
        } else if (loops) {
          _frame = 0;
          _source = null;
          onFrame.emit(0);
          onLoop.emit();
        } else {
          _elapsed = 0;
          _finished = true;
          onFinish.emit();

          if (cleanup) {
            detach();
          }

          return;
        }
      }
    });

    void painter(Canvas canvas, Paint paint) {
      canvas.drawImageRect(
        _sprite.image(_row),
        _source ??= _sprite.rect(_row, _frame),
        _destination ??= .fromLTWH(0, 0, width, height),
        paint,
      );
    }

    draw((canvas) {
      palette.draw(canvas, painter);
    });

    debugDraw((canvas) {
      canvas.drawRect(.fromLTWH(0, 0, width, height), DEBUG_TRANSFORM_PAINT);
    });
  }

  /// Re-resolves [sprite] through [Sprite.reload], so an image replaced in
  /// the cache reaches the screen without rebuilding this node.
  @override
  void reassemble() {
    _sprite = _sprite.reload();

    // Clamp the playhead if the replacement is smaller. A row that went away
    // takes its frame with it.
    if (_row >= _sprite.rows) {
      _row = 0;
      _frame = 0;
    } else if (_frame >= _sprite.frames(_row)) {
      _frame = 0;
    }

    _source = null;
    _destination = null;
  }

  /// Plays [row] from the given [frame], or whichever row [key] names.
  ///
  /// ```dart
  /// // Animates the third row from its start.
  /// sprite.play(row: 2);
  ///
  /// // Animates whichever row the sprite calls 'jump'.
  /// sprite.play(key: 'jump');
  /// ```
  ///
  /// [loop] overrides what the row states, until the next call. It also clears
  /// [isFinished], so a non-looping sprite that already finished runs again
  /// from wherever this puts it.
  void play({
    T? key,
    int row = 0,
    int frame = 0,
    bool? loop,
  }) {
    assert(key == null || row == 0, 'Must supply a key or a row, but not both.');

    if (key != null) {
      final named = _sprite.rowOf(key);

      if (named == null) {
        throw ArgumentError.value(key, 'key', 'No such row.');
      }

      row = named;
    }

    if (row < 0) {
      throw ArgumentError.value(row, 'row', 'Cannot be negative.');
    }

    if (row >= _sprite.rows) {
      throw ArgumentError.value(row, 'row', 'Only ${_sprite.rows} rows available.');
    }

    if (frame < 0) {
      throw ArgumentError.value(frame, 'frame', 'Cannot be negative.');
    }

    final frames = _sprite.frames(row);

    if (frame >= frames) {
      throw ArgumentError.value(frame, 'frame', 'That row only plays $frames frames.');
    }

    _row = row;
    _frame = frame;
    _loop = loop;
    _elapsed = 0;
    _finished = false;
    _source = null;
    _destination = null;
  }
}
