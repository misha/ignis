import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:ignis/src/bounds.dart';
import 'package:ignis/src/debug.dart';
import 'package:ignis/src/intersection_system.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/transform_node.dart';
import 'package:ignis/src/shape.dart';

/// A pointer hit area.
///
/// A node wanting more than one gesture just adds more input nodes; [priority]
/// decides who gets dibs when their shapes overlap.
///
/// TODO: Add input documentation to the README.
abstract class InputNode extends TransformNode {
  /// The shape of the node's hit area.
  Shape shape;

  InputNode({
    required this.shape,
    super.position,
    super.scale,
    super.angle,
    super.size,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  });

  /// Registers [event] with this node's gesture recognizer, if it has one.
  ///
  /// [globalToLocal] converts a global (window) position into scene space.
  /// Recognizers whose details don't carry a correctly-transformed position
  /// of their own (namely drag) need it to stay accurate when scaled.
  @internal
  void register(PointerDownEvent event, Offset Function(Offset) globalToLocal) {
    // Nothing to do.
  }

  static final _BOUNDS_SCRATCH = Aabb2();

  @override
  bool containsPoint(Vector2 point) {
    const SYSTEM = StandardIntersectionSystem();
    computeWorldBounds(this, shape, _BOUNDS_SCRATCH.mutate());

    return switch (shape) {
      .rectangle => SYSTEM.rectanglePoint(_BOUNDS_SCRATCH, point),
      .circle => SYSTEM.circlePoint(_BOUNDS_SCRATCH, point),
    };
  }

  /// Converts [scenePoint] into this node's local space.
  ///
  /// TODO: Feels bad here. Maybe a TransformNode concern?
  Vector2 toLocal(Vector2 scenePoint) {
    final inverse = absoluteTransform()..mutate().invert();
    return scenePoint.transformWith(inverse);
  }

  @override
  void debugRenderTransformed(Canvas canvas) {
    super.debugRenderTransformed(canvas);

    switch (shape) {
      case .circle:
        canvas.drawOval(shape.rect(size), DEBUG_INPUT_PAINT);

      case .rectangle:
        canvas.drawRect(shape.rect(size), DEBUG_INPUT_PAINT);
    }
  }
}
