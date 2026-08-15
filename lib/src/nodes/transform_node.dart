import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/debug.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/owners/angle_owner.dart';
import 'package:ignis/src/owners/position_owner.dart';
import 'package:ignis/src/owners/scale_owner.dart';

class TransformNode extends Node implements PositionOwner, ScaleOwner, AngleOwner {
  /// This node's position. Defaults to (0, 0).
  @override
  final MVector2 position;

  /// This node's scale. Defaults to (1, 1).
  @override
  final MVector2 scale;

  /// This node's clockwise rotation, in radians. Defaults to 0.
  @override
  double angle;

  TransformNode({
    Vector2? position,
    Vector2? scale,
    double? angle,
    super.enabled,
    super.priority,
    super.children,
  }) : position = .copy(position ?? .zero),
       scale = .copy(scale ?? .all(1)),
       angle = angle ?? 0;

  /// The distance between this node's absolute position and [other]'s.
  double distance(TransformNode other) => absolutePosition.distance(other.absolutePosition);

  /// The squared distance between this node's absolute position and [other]'s.
  double distance2(TransformNode other) => absolutePosition.distance2(other.absolutePosition);

  final MMatrix3 _lastLocalTransform = .identity();

  /// This node's local transform.
  ///
  /// The returned matrix is owned by this node and should not be retained.
  MMatrix3 get localTransform {
    final transform = _lastLocalTransform;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    transform.setValues(
      // dart format off
      cosA * scale.x,   sinA * scale.x, 0,
      -sinA * scale.y,  cosA * scale.y, 0,
      position.x,       position.y,     1,
      // dart format on
    );

    return transform;
  }

  final MMatrix3 _lastAbsoluteTransform = .identity();

  /// This node's transform composed with every [TransformNode] ancestor,
  /// stopping at (but not including) [upTo].
  ///
  /// The returned matrix is owned by this node and should not be retained.
  MMatrix3 absoluteTransform([Node? upTo]) {
    final transform = _lastAbsoluteTransform;
    transform.setFrom(localTransform);
    var current = parent;

    while (current != null && !identical(current, upTo)) {
      if (current is TransformNode) {
        transform.premultiply(current.localTransform);
      }

      current = current.parent;
    }

    return transform;
  }

  /// This node's [position], composed with the transform of every
  /// [TransformNode] ancestor, stopping at (but not including) [upTo].
  ///
  /// The returned vector is a fresh copy, free for the caller to mutate.
  MVector2 scenePosition([Node? upTo]) {
    final absolute = MVector2.copy(position);
    var current = parent;

    while (current != null && !identical(current, upTo)) {
      if (current is TransformNode) {
        absolute.transform(current.localTransform);
      }

      current = current.parent;
    }

    return absolute;
  }

  /// This node's [position] in scene space.
  MVector2 get absolutePosition => scenePosition();

  /// The nearest [T] to this node among [within]'s descendants, or null if
  /// there is none.
  ///
  /// Defaults to searching this node's whole tree. Never returns this node.
  T? nearest<T extends TransformNode>([Node? within]) {
    var root = within;

    if (root == null) {
      root = this;

      while (root!.parent != null) {
        root = root.parent;
      }
    }

    final absolute = absolutePosition;
    T? closest;
    var closestDistance2 = double.infinity;

    for (final descendant in root.descendants) {
      if (descendant is! T || identical(descendant, this)) continue;

      final distance2 = descendant.absolutePosition.distance2(absolute);

      if (distance2 < closestDistance2) {
        closest = descendant;
        closestDistance2 = distance2;
      }
    }

    return closest;
  }

  final _lastRenderTransform = Float64List(16)
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
    canvas.transform(renderTransform);
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
