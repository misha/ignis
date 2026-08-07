import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:ignis/src/debug.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/sized_node.dart';
import 'package:ignis/src/shape.dart';

/// A pointer hit area.
///
/// A node wanting more than one gesture just adds more input nodes; [priority]
/// decides who gets dibs when their shapes overlap.
abstract class InputNode extends SizedNode {
  /// The shape of the node's hit area.
  Shape shape;

  InputNode({
    required this.shape,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  });

  @override
  double get width => shape.width;

  @override
  double get height => shape.height;

  /// Registers [event] with this node's gesture recognizer, if it has one.
  ///
  /// [globalToLocal] converts a global (window) position into scene space.
  /// Recognizers whose details don't carry a correctly-transformed position
  /// of their own (namely drag) need it to stay accurate when scaled.
  @internal
  void register(PointerDownEvent event, Offset Function(Offset) globalToLocal) {
    // Nothing to do.
  }

  @override
  bool containsPoint(Vector2 point) {
    final local = toLocal(point);
    final adjusted = Vector2(
      local.x + anchor.x * width,
      local.y + anchor.y * height,
    );

    switch (shape) {
      case Rectangle(:final size):
        return adjusted.x >= 0 && //
            adjusted.x <= size.x &&
            adjusted.y >= 0 &&
            adjusted.y <= size.y;

      case Circle(:final radius):
        final dx = adjusted.x - radius;
        final dy = adjusted.y - radius;
        return dx * dx + dy * dy <= radius * radius;
    }
  }

  /// Converts [scenePoint] into this node's local space.
  ///
  /// TODO: Feels bad here. Maybe a SizedNode concern?
  Vector2 toLocal(Vector2 scenePoint) {
    final inverse = absoluteTransform()..mutate().invert();
    return scenePoint.transformWith(inverse);
  }

  @override
  void debugRenderAnchored(Canvas canvas) {
    switch (shape) {
      case Circle():
        canvas.drawOval(shape.rect(), DEBUG_INPUT_PAINT);

      case Rectangle():
        canvas.drawRect(shape.rect(), DEBUG_INPUT_PAINT);
    }
  }
}
