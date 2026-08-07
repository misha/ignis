import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:ignis/src/debug.dart';
import 'package:ignis/src/node.dart';
import 'package:ignis/src/math.dart';

class TransformNode extends Node {
  /// This node's position. Defaults to (0, 0).
  final Vector2 position;

  /// This node's scale. Defaults to (1, 1).
  final Vector2 scale;

  /// This node's clockwise rotation, in radians. Defaults to 0.
  double angle;

  TransformNode({
    Vector2? position,
    Vector2? scale,
    double? angle,
    super.enabled,
    super.priority,
    super.children,
  }) : position = position ?? .zero(),
       scale = scale ?? .all(1),
       angle = angle ?? 0;

  /// The distance between this node's [position] and [other]'s.
  double distance(TransformNode other) => position.distance(other.position);

  /// The squared distance between this node's [position] and [other]'s.
  double distance2(TransformNode other) => position.distance2(other.position);

  final Matrix3 _lastLocalTransform = .identity();

  /// This node's local transform.
  ///
  /// The returned matrix is owned by this node and should not be retained.
  Matrix3 get localTransform {
    final transform = _lastLocalTransform;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    transform.mutate().setValues(
      // dart format off
      cosA * scale.x,   sinA * scale.x, 0,
      -sinA * scale.y,  cosA * scale.y, 0,
      position.x,       position.y,     1,
      // dart format on
    );

    return transform;
  }

  final Matrix3 _lastAbsoluteTransform = .identity();

  /// This node's transform composed with every [TransformNode] ancestor,
  /// stopping at (but not including) [upTo].
  ///
  /// The returned matrix is owned by this node and should not be retained.
  Matrix3 absoluteTransform([Node? upTo]) {
    final transform = _lastAbsoluteTransform;
    transform.mutate().setFrom(localTransform);
    var current = parent;

    while (current != null && !identical(current, upTo)) {
      if (current is TransformNode) {
        transform.mutate().premultiply(current.localTransform);
      }

      current = current.parent;
    }

    return transform;
  }

  final Float64List _lastRenderTransform = Float64List(16)
    ..[10] = 1
    ..[15] = 1;

  /// This node's render transform. Equivalent to [localTransform], except
  /// that it's stored in a [Canvas]-friendly `typed_data` structure for
  /// performance reasons.
  ///
  /// The returned float list is owned by this node and should not be retained.
  @visibleForTesting
  Float64List get renderTransform {
    final transform = _lastRenderTransform;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    transform
      ..[0] = cosA * scale.x
      ..[1] = sinA * scale.x
      ..[4] = -sinA * scale.y
      ..[5] = cosA * scale.y
      ..[12] = position.x
      ..[13] = position.y;

    return transform;
  }

  @override
  @mustCallSuper
  void render(Canvas canvas) {
    canvas.save();
    canvas.transform(renderTransform);
    renderTransformed(canvas);
    super.render(canvas);
    canvas.restore();
  }

  /// Draws this node's visuals, in a coordinate space where (0, 0) is [position].
  @visibleForOverriding
  void renderTransformed(Canvas canvas) {
    // Nothing to do.
  }

  @override
  @mustCallSuper
  void debugRender(Canvas canvas) {
    canvas.save();
    canvas.transform(_lastRenderTransform);
    debugRenderTransformed(canvas);
    super.debugRender(canvas);
    canvas.restore();
  }

  /// Draws this node's debug visuals, in the same coordinate space as
  /// [renderTransformed].
  ///
  /// The default implementation draws a 2-pixel cross marking [position].
  /// Override to customize or replace it; call `super` to keep the cross
  /// alongside your own drawing.
  @visibleForOverriding
  void debugRenderTransformed(Canvas canvas) {
    canvas.drawLine(.new(-1, 0), .new(1, 0), DEBUG_TRANSFORM_PAINT);
    canvas.drawLine(.new(0, -1), .new(0, 1), DEBUG_TRANSFORM_PAINT);
  }
}
