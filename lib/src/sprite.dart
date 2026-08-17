import 'dart:ui';

import 'package:ignis/src/globals.dart';
import 'package:ignis/src/math.dart';

/// The frames a [SpriteNode] draws, and how long each is held.
///
/// Three implementations ship: a [SpriteImage] is one image, a [SpriteSheet]
/// cuts an image into a grid, and a [SpriteGroup] lays several of either end to
/// end. Implement this to draw frames packed some other way.
///
/// A row is the unit. Everything but [rows] answers for one, so an
/// implementation is free to hold every row in its own image, at its own size.
///
/// [T] is what rows are named with, where they are named at all: an enum, a
/// [String], anything with an `==`. Every sprite composed with another shares
/// its key type, so [rowOf] answers for the whole tree.
abstract class Sprite<T> {
  const Sprite();

  /// How many rows of frames this holds.
  int get rows;

  /// The image [row] is drawn from.
  Image image(int row);

  /// The size of one frame of [row], which a [SpriteNode] takes as its own.
  Vector2 size(int row);

  /// How many frames [row] plays.
  int frames(int row);

  /// Where frame [index] of [row] sits in [image].
  Rect rect(int row, int index);

  /// How long frame [index] of [row] is held, in seconds.
  ///
  /// Infinite where the frame is never left.
  double duration(int row, int index);

  /// Whether [row] starts over after its last frame.
  bool loops(int row);

  /// The row [key] names, or null where nothing here answers to it.
  int? rowOf(T key) => null;

  /// Re-resolves this sprite against [Ignis.cache].
  ///
  /// Returns this unless what it was built from has since been replaced, so a
  /// caller can tell whether anything changed by identity.
  Sprite<T> reload() => this;
}
