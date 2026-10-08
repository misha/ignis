// SPDX-AI-Disclosure: ai-assisted

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:ignis/src/assets/cache.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/message.dart';
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
/// The [shape] is one frame, so [anchor], hit testing, and layout work off the
/// frame. [speed] scales the sprite's own rate, and [play] chooses the entry.
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

  @override
  set shape(Shape value) => throw UnsupportedError('A SpriteNode is sized by its frame.');

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
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        parent?.post(SpriteResize(this));

      case Update(:final dt):
        final current = _current;
        if (current.isFinished) break;
        final amount = dt * speed;
        if (amount <= 0 || !amount.isFinite) break;

        current._elapsed += amount;

        // Every pass re-reads the state, so a handler calling play() redirects
        // this loop instead of racing it.
        while (true) {
          final duration = current._entry.duration(current.frame);

          if (duration <= 0 || !duration.isFinite) {
            current._elapsed = 0;
            break;
          }

          if (current._elapsed < duration) break;
          current._elapsed -= duration;
          final next = current.frame + 1;

          if (next < current._entry.frames) {
            current._seek(next);
          } else if (current.loops) {
            current._seek(0);
            parent?.post(SpriteLoop(this));
          } else {
            current._elapsed = 0;
            current._finished = true;
            parent?.post(SpriteFinish(this));

            if (cleanup) {
              detach();
            }

            break;
          }
        }

      case Draw(:final canvas):
        palette.draw(canvas, _paint);
    }

    if (kDebugMode) {
      switch (message) {
        case Build():
          Ignis.cache.subscribe(this);

        case CacheChange():
          _sprite = _sprite.reload();

          // Follow the entry by name. A dropped entry falls back to the first; a
          // shorter one starts over.
          final entry = _sprite.resolve(_current.key);

          if (entry == null) {
            _select(_sprite.entries.first, 0);
            break;
          }

          final frame = _current.frame;
          _select(entry, frame < entry.frames ? frame : 0);

        case Destroy():
          Ignis.cache.unsubscribe(this);
      }
    }
  }

  void _paint(Canvas canvas, Paint paint) {
    final current = _current;

    canvas.drawImageRect(
      current._entry.image,
      current._source ??= current._entry.rect(current.frame),
      current._destination ??= .fromLTWH(0, 0, width, height),
      paint,
    );
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
      .._elapsed = 0;

    _select(entry, frame);
  }

  /// Moves onto [frame] of [entry], posting [SpriteResize] if that changes this
  /// node's size.
  void _select(SpriteEntry<T> entry, int frame) {
    final size = _current.shape.size;
    _current._select(entry, frame);
    if (_current.shape.size != size) parent?.post(SpriteResize(this));
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

/// Emitted when [sprite]'s looping animation wraps to the start of its entry.
final class SpriteLoop extends Message {
  final SpriteNode sprite;

  const SpriteLoop(this.sprite);
}

/// Emitted when [sprite] builds, and whenever the frame it draws changes size.
final class SpriteResize extends Message {
  final SpriteNode sprite;

  const SpriteResize(this.sprite);
}

/// Emitted when [sprite]'s non-looping animation reaches its final frame.
final class SpriteFinish extends Message {
  final SpriteNode sprite;

  const SpriteFinish(this.sprite);
}
