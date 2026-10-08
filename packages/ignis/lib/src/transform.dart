import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/owners/angle_owner.dart';
import 'package:ignis/src/owners/position_owner.dart';
import 'package:ignis/src/owners/scale_owner.dart';

/// A [position], [scale], and [angle].
mixin Transform implements PositionOwner, ScaleOwner, AngleOwner {
  /// The position. Defaults to (0, 0).
  @override
  final MVector2 position = .zero();

  /// The scale. Defaults to (1, 1).
  @override
  final MVector2 scale = .all(1);

  /// The clockwise rotation, in radians. Defaults to 0.
  @override
  double angle = 0;

  final MMatrix3 _lastLocalTransform = .identity();

  /// The local transform.
  ///
  /// The returned matrix is owned by this object and should not be retained.
  MMatrix3 get localTransform {
    final transform = _lastLocalTransform;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final a = cosA * scale.x;
    final b = sinA * scale.x;
    final c = -sinA * scale.y;
    final d = cosA * scale.y;

    transform.setValues(
      // dart format off
      a, b, 0,
      c, d, 0,
      position.x, position.y, 1,
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
  Float64List get renderTransform {
    final transform = _lastRenderTransform;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final a = cosA * scale.x;
    final b = sinA * scale.x;
    final c = -sinA * scale.y;
    final d = cosA * scale.y;

    transform
      ..[0] = a
      ..[1] = b
      ..[4] = c
      ..[5] = d
      ..[12] = position.x
      ..[13] = position.y;

    return transform;
  }
}
