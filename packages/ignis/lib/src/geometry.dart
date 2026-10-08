import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:ignis/src/anchor.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/owners/anchor_owner.dart';
import 'package:ignis/src/shape.dart';
import 'package:ignis/src/transform.dart';

/// A [shape] on a [Transform], measured from its [anchor].
mixin Geometry on Transform implements AnchorOwner {
  /// The shape. Defaults to no shape.
  Shape shape = .none;

  /// Where [shape] sits relative to [position]. Defaults to `topLeft`.
  @override
  Anchor anchor = .topLeft;

  /// The dimensions, determined by the bounds of [shape].
  Vector2 get size => shape.size;

  /// The width.
  double get width => size.x;

  /// The height.
  double get height => size.y;

  /// The [anchor]'s point in local space.
  Vector2 pointAt(Anchor anchor) => .new(anchor.x * width, anchor.y * height);

  /// The center of [shape], in local space.
  Vector2 get center => pointAt(.center);

  final MMatrix3 _lastLocalTransform = .identity();

  /// The local transform, offset so [anchor] sits on [position].
  ///
  /// The returned matrix is owned by this object and should not be retained.
  @override
  MMatrix3 get localTransform {
    final transform = _lastLocalTransform;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final a = cosA * scale.x;
    final b = sinA * scale.x;
    final c = -sinA * scale.y;
    final d = cosA * scale.y;

    final anchor = this.anchor;

    if (anchor.isZero) {
      transform.setValues(
        // dart format off
        a, b, 0,
        c, d, 0,
        position.x, position.y, 1,
        // dart format on
      );

      return transform;
    }

    final offsetX = -anchor.x * width;
    final offsetY = -anchor.y * height;

    transform.setValues(
      // dart format off
      a, b, 0,
      c, d, 0,
      offsetX * a + offsetY * c + position.x,
      offsetX * b + offsetY * d + position.y, 1,
      // dart format on
    );

    return transform;
  }

  final _lastRenderTransform = Float64List(16)
    ..[10] = 1
    ..[15] = 1;

  /// The render transform. Equivalent to [localTransform], except that it's
  /// stored in a `Canvas`-friendly `typed_data` structure for performance
  /// reasons.
  ///
  /// The returned list is owned by this object and should not be retained.
  @override
  Float64List get renderTransform {
    final transform = _lastRenderTransform;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final a = cosA * scale.x;
    final b = sinA * scale.x;
    final c = -sinA * scale.y;
    final d = cosA * scale.y;

    final anchor = this.anchor;

    if (anchor.isZero) {
      transform
        ..[0] = a
        ..[1] = b
        ..[4] = c
        ..[5] = d
        ..[12] = position.x
        ..[13] = position.y;

      return transform;
    }

    final offsetX = -anchor.x * width;
    final offsetY = -anchor.y * height;

    transform
      ..[0] = a
      ..[1] = b
      ..[4] = c
      ..[5] = d
      ..[12] = offsetX * a + offsetY * c + position.x
      ..[13] = offsetX * b + offsetY * d + position.y;

    return transform;
  }
}
