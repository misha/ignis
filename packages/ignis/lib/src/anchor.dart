// SPDX-AI-Disclosure: none

import 'package:ignis/src/math.dart';

/// Represents a relative position inside some 2D object with a rectangular
/// size or bounding box.
///
/// Think of it as the place where you "grab" or "hold" the object.
///
/// In nodes, the anchor is where the node position is measured from. For
/// example, if a node's position is (100, 100) the anchor reflects what exact
/// point of the node that is positioned at (100, 100), as a relative fraction
/// of the size of the object.
///
/// The "default" anchor in most cases is [topLeft].
///
/// The anchor is represented by a fraction of the size (in each axis), where 0
/// in x-axis means left, 0 in y-axis means top, 1 in x-axis means right and 1
/// in y-axis means bottom.
///
/// Just a [Vector2] under the hood, with canonical instances for common
/// positions.
///
/// Original concept and comments from Flame.
extension type const Anchor._(Vector2 value) implements Vector2 {
  /// The relative x position with respect to the object's width;
  /// 0 means totally to the left (beginning) and 1 means totally to the
  /// right (end).
  double get x => value.x;

  /// The relative y position with respect to the object's height;
  /// 0 means totally to the top (beginning) and 1 means totally to the
  /// bottom (end).
  double get y => value.y;

  /// Returns the anchor on the opposite side of this anchor.
  Anchor get opposite => Anchor(1 - x, 1 - y);

  Anchor(double x, double y) : this._(Vector2(x, y));

  static const Anchor topLeft = Anchor._(Vector2(0.0, 0.0));
  static const Anchor topCenter = Anchor._(Vector2(0.5, 0.0));
  static const Anchor topRight = Anchor._(Vector2(1.0, 0.0));
  static const Anchor centerLeft = Anchor._(Vector2(0.0, 0.5));
  static const Anchor center = Anchor._(Vector2(0.5, 0.5));
  static const Anchor centerRight = Anchor._(Vector2(1.0, 0.5));
  static const Anchor bottomLeft = Anchor._(Vector2(0.0, 1.0));
  static const Anchor bottomCenter = Anchor._(Vector2(0.5, 1.0));
  static const Anchor bottomRight = Anchor._(Vector2(1.0, 1.0));
}
