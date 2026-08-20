import 'package:ignis/src/sprite.dart';
import 'package:ignis/src/sprites/sprite_entry.dart';

/// Several [Sprite]s laid end to end, addressed as one run of entries.
///
/// ```dart
/// final slime = SpriteGroup([
///   SpriteAnimation('assets/idle.png', .all(56), fps: 16),
///   SpriteAnimation('assets/jump.png', .all(56), fps: 24),
/// ]);
///
/// node.play(1);
/// ```
///
/// Entries are numbered straight through and answer to their index, so a part
/// contributes as many as it holds and the next one carries on where it left
/// off. Each part brings its own image, frame size, rates and looping, and
/// anything implementing [Sprite] can be one of them.
///
/// A [SpriteMap] is the same run of entries under names of your choosing.
class SpriteGroup extends Sprite<int> {
  /// What this draws, in the order their entries are numbered.
  final List<Sprite<int>> parts;

  @override
  late final List<SpriteEntry<int>> entries;

  SpriteGroup(Iterable<Sprite<int>> parts) //
    : parts = .unmodifiable(parts) {
    if (this.parts.isEmpty) {
      throw ArgumentError.value(
        parts,
        'parts',
        'Must hold at least one.',
      );
    }

    var index = 0;

    entries = [
      for (final part in this.parts)
        for (final entry in part.entries) //
          entry.rename(index, index++),
    ];
  }

  @override
  SpriteEntry<int>? resolve(int key) {
    if (key < 0 || key >= entries.length) return null;
    return entries[key];
  }

  @override
  SpriteGroup reload() {
    List<Sprite<int>>? resolved;

    for (var index = 0; index < parts.length; index += 1) {
      final part = parts[index];
      final reloaded = part.reload();
      if (identical(reloaded, part)) continue;
      resolved ??= List.of(parts);
      resolved[index] = reloaded;
    }

    if (resolved == null) return this;
    return SpriteGroup(resolved);
  }
}
