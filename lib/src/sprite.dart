import 'dart:ui';

import 'package:ignis/src/globals.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/sprites/sprite_entry.dart';
import 'package:ignis/src/sprites/sprite_key.dart';

/// The frames a [SpriteNode] draws, and how long each is held.
///
/// Three implementations ship: a [SpriteImage] is one image, a [SpriteSheet]
/// cuts an image into a grid, and a [SpriteGroup] lays several of either end to
/// end. Implement this to draw frames packed some other way.
///
/// An entry is the unit. Everything but [length] answers for one, so an
/// implementation is free to hold every entry in its own image, at its own
/// size.
///
/// [T] is what entries are identified by, where they are named at all: an
/// enum, a [String], anything with an `==`. Every sprite composed with another
/// shares its id type, so [resolve] answers for the whole tree.
abstract class Sprite<T> {
  const Sprite();

  /// How many entries this holds.
  int get length;

  /// The image entry [index] is drawn from. Make this fast.
  Image image(int index);

  /// The frame size of entry [index], which a [SpriteNode] takes as its own.
  Vector2 size(int index);

  /// How many frames entry [index] plays.
  int frames(int index);

  /// Where [frame] of entry [index] sits in [image].
  Rect rect(int index, int frame);

  /// How long [frame] of entry [index] is held, in seconds.
  ///
  /// Infinite where the frame is never left.
  double duration(int index, int frame);

  /// Whether entry [index] starts over after its last frame.
  bool loops(int index);

  /// The entry [key] looks up, or null where nothing here answers to it.
  SpriteEntry<T>? resolve(SpriteKey<T> key);

  /// Re-resolves this sprite against [Ignis.cache].
  ///
  /// Returns this unless what it was built from has since been replaced, so a
  /// caller can tell whether anything changed by identity.
  Sprite<T> reload() => this;
}
