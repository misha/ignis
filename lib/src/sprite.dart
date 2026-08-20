import 'package:ignis/src/globals.dart';
import 'package:ignis/src/sprites/sprite_entry.dart';

/// The frames a [SpriteNode] draws, and how long each is held.
///
/// Four implementations ship: a [SpriteImage] is one image, a [SpriteSheet]
/// cuts an image into a grid, a [SpriteGroup] lays several of either end to
/// end, and a [SpriteMap] does the same under names of your choosing. Implement
/// this to draw frames packed some other way.
///
/// An entry is the unit, and a [SpriteEntry] states everything one is, so an
/// implementation is free to hold every entry in its own image, at its own
/// size.
///
/// A sprite only has one name at a time, and that name is [T]. [SpriteNode]
/// then enforces that all sprites use the same naming scheme.
abstract class Sprite<T> {
  const Sprite();

  /// What this holds, in the order its entries are numbered.
  ///
  /// Every entry sits at its own place in this, so `entries[i].index` is `i`.
  List<SpriteEntry<T>> get entries;

  /// The entry [key] names, or null where nothing here answers to it.
  SpriteEntry<T>? resolve(T key);

  /// Re-resolves this sprite against [Ignis.cache].
  ///
  /// Returns `this` unless what it was built from has since been replaced, so
  /// the caller can tell whether anything changed by identity.
  Sprite<T> reload() => this;
}
