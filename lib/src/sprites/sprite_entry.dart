import 'package:ignis/src/sprite.dart';

/// An entry of a [Sprite], looked up.
final class SpriteEntry<T> {
  /// Where the entry sits in the sprite.
  final int index;

  /// What the entry answers to, or null where it goes unnamed.
  final T? id;

  const SpriteEntry(this.index, this.id);

  @override
  String toString() {
    if (id != null) return 'SpriteEntry($index, $id)';
    return 'SpriteEntry($index)';
  }
}
