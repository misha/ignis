import 'dart:typed_data';

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
/// The "default" anchor in most cases is [topLeft]. Null anchor values are also
/// interpreted as a [topLeft] anchor.
///
/// The anchor is represented by a fraction of the size (in each axis), where 0
/// in x-axis means left, 0 in y-axis means top, 1 in x-axis means right and 1
/// in y-axis means bottom.
///
/// Original concept and comments from Flame.
class Anchor implements Mutable<MutableAnchor> {
  final _storage = Float64List(2);

  /// The relative x position with respect to the object's width;
  /// 0 means totally to the left (beginning) and 1 means totally to the
  /// right (end).
  double get x => _storage[0];

  /// The relative y position with respect to the object's height;
  /// 0 means totally to the top (beginning) and 1 means totally to the
  /// bottom (end).
  double get y => _storage[1];

  /// Returns the anchor on the opposite side of this anchor.
  Anchor get opposite => Anchor(1 - x, 1 - y);

  factory Anchor.topLeft() => Anchor(0.0, 0.0);
  factory Anchor.topCenter() => Anchor(0.5, 0.0);
  factory Anchor.topRight() => Anchor(1.0, 0.0);
  factory Anchor.centerLeft() => Anchor(0.0, 0.5);
  factory Anchor.center() => Anchor(0.5, 0.5);
  factory Anchor.centerRight() => Anchor(1.0, 0.5);
  factory Anchor.bottomLeft() => Anchor(0.0, 1.0);
  factory Anchor.bottomCenter() => Anchor(0.5, 1.0);
  factory Anchor.bottomRight() => Anchor(1.0, 1.0);

  Anchor(double x, double y) {
    _storage[0] = x;
    _storage[1] = y;
  }

  /// Take your position [position] that is on this anchor and give back what
  /// that position it would be on in the [other] anchor with a size of [size].
  Vector2 toOtherAnchorPosition(
    Vector2 position,
    Anchor other,
    Vector2 size, [
    MutableVector2? out,
  ]) {
    if (this == other) return position;
    out ??= Vector2.zero().mutate();
    out
      ..x = other.x - x
      ..y = other.y - y
      ..multiply(size)
      ..add(position);

    return out.source;
  }

  @override
  MutableAnchor mutate() => MutableAnchor._(this);

  @override
  bool operator ==(Object other) =>
      other is Anchor && //
      x == other.x &&
      y == other.y;

  @override
  int get hashCode => x.hashCode * 31 + y.hashCode;
}

extension type MutableAnchor._(Anchor source) {
  double get x => source.x; // coverage:ignore-line
  double get y => source.y; // coverage:ignore-line

  set x(double value) {
    source._storage[0] = value;
  }

  set y(double value) {
    source._storage[1] = value;
  }

  void setValues(double x, double y) {
    this.x = x;
    this.y = y;
  }

  void setFrom(Anchor other) {
    x = other.x;
    y = other.y;
  }
}
