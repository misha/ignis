import 'package:ignis/src/sprite.dart';

/// How an entry of a [Sprite] is looked up: by its index, or by its id.
sealed class SpriteKey<T> {
  const SpriteKey();

  /// The entry sitting at [index].
  const factory SpriteKey.index(int index) = SpriteIndex<T>;

  /// The entry answering to [id].
  const factory SpriteKey.id(T id) = SpriteId<T>;
}

/// An entry looked up by where it sits in the sprite.
final class SpriteIndex<T> extends SpriteKey<T> {
  /// Where the entry sits.
  final int index;

  const SpriteIndex(this.index);

  @override
  String toString() => 'SpriteKey(#$index)';
}

/// An entry looked up by what it answers to.
final class SpriteId<T> extends SpriteKey<T> {
  /// What the entry answers to.
  final T id;

  const SpriteId(this.id);

  @override
  String toString() => 'SpriteKey(id=$id)';
}
