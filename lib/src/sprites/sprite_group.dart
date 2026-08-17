import 'dart:ui';

import 'package:ignis/src/math.dart';
import 'package:ignis/src/sprite.dart';

/// One row of a [SpriteGroup], and where it came from.
final class _Slot<T> {
  final Sprite<T> sprite;
  final int row;

  const _Slot(this.sprite, this.row);
}

/// Several [Sprite]s laid end to end, addressed as one run of rows.
///
/// ```dart
/// final slime = SpriteGroup([
///   SpriteSheet('assets/idle.png', .all(56), fps: 16, rows: [.new(key: 'idle')]),
///   SpriteSheet('assets/jump.png', .all(56), fps: 24, rows: [.new(key: 'jump')]),
/// ]);
///
/// node.play(key: 'jump');
/// ```
///
/// Rows are numbered straight through, so a part contributes as many as it
/// holds and the next one carries on where it left off. Parts answer for their
/// own rows, so each brings its own image, frame size, rates and looping.
/// Anything implementing [Sprite] can be one of them.
///
/// Names come from the parts, never from here: [rowOf] asks each of them in
/// turn and shifts the answer by the rows before it.
class SpriteGroup<T> extends Sprite<T> {
  /// What this draws, in the order their rows are numbered.
  final List<Sprite<T>> parts;

  @override
  late final int rows;

  late final List<_Slot<T>> _slots;
  late final List<int> _offsets;

  SpriteGroup(Iterable<Sprite<T>> parts) //
    : parts = .unmodifiable(parts) {
    if (this.parts.isEmpty) {
      throw ArgumentError.value(parts, 'parts', 'Must hold at least one.');
    }

    _offsets = .filled(this.parts.length, 0);
    var offset = 0;

    for (var index = 0; index < this.parts.length; index += 1) {
      _offsets[index] = offset;
      offset += this.parts[index].rows;
    }

    _slots = [
      for (final part in this.parts)
        for (var row = 0; row < part.rows; row += 1) //
          _Slot<T>(part, row),
    ];

    rows = _slots.length;
  }

  @override
  Image image(int row) {
    final slot = _slots[row];
    return slot.sprite.image(slot.row);
  }

  @override
  Vector2 size(int row) {
    final slot = _slots[row];
    return slot.sprite.size(slot.row);
  }

  @override
  int frames(int row) {
    final slot = _slots[row];
    return slot.sprite.frames(slot.row);
  }

  @override
  Rect rect(int row, int index) {
    final slot = _slots[row];
    return slot.sprite.rect(slot.row, index);
  }

  @override
  double duration(int row, int index) {
    final slot = _slots[row];
    return slot.sprite.duration(slot.row, index);
  }

  @override
  bool loops(int row) {
    final slot = _slots[row];
    return slot.sprite.loops(slot.row);
  }

  @override
  int? rowOf(T key) {
    for (var index = 0; index < parts.length; index += 1) {
      final row = parts[index].rowOf(key);
      if (row != null) return _offsets[index] + row;
    }

    return null;
  }

  @override
  SpriteGroup<T> reload() {
    List<Sprite<T>>? resolved;

    for (var index = 0; index < parts.length; index += 1) {
      final part = parts[index];
      final reloaded = part.reload();
      if (identical(reloaded, part)) continue;
      resolved ??= List.of(parts);
      resolved[index] = reloaded;
    }

    return resolved == null ? this : SpriteGroup<T>(resolved);
  }
}
