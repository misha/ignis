import 'dart:ui';

import 'package:ignis/src/bounds.dart';
import 'package:ignis/src/debug.dart';
import 'package:ignis/src/intersection_system.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/transform_node.dart';
import 'package:ignis/src/pointer_info.dart';
import 'package:ignis/src/shape.dart';
import 'package:ignis/src/signal.dart';

/// A pointer-hit area, independent of any sibling collider's physics bounds.
///
/// Implements [containsPoint] so [hitTest] can find it.
class InputNode extends TransformNode {
  /// The shape of the node's hit area.
  Shape shape;

  /// Emitted when a pointer goes down over this node. This node then
  /// captures the pointer, so [onPointerMove] and [onPointerUp] keep firing
  /// for it even once it leaves this node's hit area.
  final onPointerDown = Signal1<PointerInfo>();

  /// Emitted while a pointer this node has captured moves.
  final onPointerMove = Signal1<PointerInfo>();

  /// Emitted when a pointer this node has captured lifts.
  final onPointerUp = Signal1<PointerInfo>();

  /// Emitted when a pointer this node has captured is cancelled.
  final onPointerCancel = Signal1<PointerInfo>();

  /// Emitted when a hovering pointer enters this node's hit area.
  final onPointerEnter = Signal1<PointerInfo>();

  /// Emitted when a hovering pointer leaves this node's hit area.
  final onPointerExit = Signal1<PointerInfo>();

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
