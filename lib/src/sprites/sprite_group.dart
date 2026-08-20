import 'dart:ui';

import 'package:ignis/src/math.dart';
import 'package:ignis/src/sprite.dart';
import 'package:ignis/src/sprites/sprite_entry.dart';
import 'package:ignis/src/sprites/sprite_key.dart';

/// One entry of a [SpriteGroup], and where it came from.
final class _Slot<T> {
  final Sprite<T> sprite;
  final int index;

  const _Slot(this.sprite, this.index);
}

/// Several [Sprite]s laid end to end, addressed as one run of entries.
///
/// ```dart
/// final slime = SpriteGroup([
///   SpriteSheet('assets/idle.png', .all(56), fps: 16, rows: [.new(id: 'idle')]),
///   SpriteSheet('assets/jump.png', .all(56), fps: 24, rows: [.new(id: 'jump')]),
/// ]);
///
/// node.play(id: 'jump');
/// ```
///
/// Entries are numbered straight through, so a part contributes as many as it
/// holds and the next one carries on where it left off. Parts answer for their
/// own entries, so each brings its own image, frame size, rates and looping.
/// Anything implementing [Sprite] can be one of them.
///
/// Names come from the parts, never from here: [resolve] asks each of them in
/// turn and shifts the answer by the entries before it.
class SpriteGroup<T> extends Sprite<T> {
  /// What this draws, in the order their entries are numbered.
  final List<Sprite<T>> parts;

  @override
  late final int length;

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
      offset += this.parts[index].length;
    }

    _slots = [
      for (final part in this.parts)
        for (var index = 0; index < part.length; index += 1) //
          _Slot<T>(part, index),
    ];

    length = _slots.length;
  }

  @override
  Image image(int index) {
    final slot = _slots[index];
    return slot.sprite.image(slot.index);
  }

  @override
  Vector2 size(int index) {
    final slot = _slots[index];
    return slot.sprite.size(slot.index);
  }

  @override
  int frames(int index) {
    final slot = _slots[index];
    return slot.sprite.frames(slot.index);
  }

  @override
  Rect rect(int index, int frame) {
    final slot = _slots[index];
    return slot.sprite.rect(slot.index, frame);
  }

  @override
  double duration(int index, int frame) {
    final slot = _slots[index];
    return slot.sprite.duration(slot.index, frame);
  }

  @override
  bool loops(int index) {
    final slot = _slots[index];
    return slot.sprite.loops(slot.index);
  }

  @override
  SpriteEntry<T>? resolve(SpriteKey<T> key) {
    switch (key) {
      case SpriteIndex(:final index):
        final slot = _slots[index];
        final resolved = slot.sprite.resolve(.index(slot.index));
        return SpriteEntry(index, resolved?.id);

      case SpriteId(:final id):
        for (var part = 0; part < parts.length; part += 1) {
          final entry = parts[part].resolve(key);

          if (entry != null) {
            final index = _offsets[part] + entry.index;
            return SpriteEntry(index, id);
          }
        }

        return null;
    }
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
