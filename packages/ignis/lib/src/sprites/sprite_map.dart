import 'package:ignis/src/sprite.dart';
import 'package:ignis/src/sprites/sprite_entry.dart';

/// Several [Sprite]s under names of your choosing.
///
/// ```dart
/// final sheet = SpriteSheet('assets/slime.png', .all(56));
///
/// final slime = SpriteMap({
///   'idle': sheet.animation(row: 0, fps: 16),
///   'jump': sheet.animation(row: 1, fps: 16),
/// });
///
/// node.play('jump');
/// ```
///
/// A name holds one entry, so what it names brings only the art: a row of a
/// sheet, a whole image, anything implementing [Sprite] that holds one thing.
/// Entries are numbered in the order the map states them.
///
/// [T] is what entries are named by: an enum, a [String], anything with `==`.
class SpriteMap<T> extends Sprite<T> {
  /// What this draws, under the names it draws them by.
  final Map<T, Sprite<int>> sprites;

  @override
  late final List<SpriteEntry<T>> entries;

  late final Map<T, SpriteEntry<T>> _keys;

  SpriteMap(Map<T, Sprite<int>> sprites) //
    : sprites = .unmodifiable(sprites) {
    if (this.sprites.isEmpty) {
      throw ArgumentError.value(
        sprites,
        'sprites',
        'Must hold at least one.',
      );
    }

    final resolved = <SpriteEntry<T>>[];
    _keys = {};

    for (final MapEntry(:key, :value) in this.sprites.entries) {
      if (value.entries.length != 1) {
        throw ArgumentError.value(
          value.entries.length,
          '$key',
          'A name holds one entry. Take the one you mean.',
        );
      }

      final entry = value.entries[0].rename(resolved.length, key);
      _keys[key] = entry;
      resolved.add(entry);
    }

    entries = List.of(resolved, growable: false);
  }

  @override
  SpriteEntry<T>? resolve(T key) => _keys[key];

  @override
  SpriteMap<T> reload() {
    Map<T, Sprite<int>>? resolved;

    for (final entry in sprites.entries) {
      final key = entry.key;
      final sprite = entry.value;
      final reloaded = sprite.reload();
      if (identical(reloaded, sprite)) continue;
      resolved ??= Map.of(sprites);
      resolved[key] = reloaded;
    }

    if (resolved == null) return this;
    return SpriteMap<T>(resolved);
  }
}
