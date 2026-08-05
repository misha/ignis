import 'dart:ui';

import 'package:ignis/src/debug.dart';
import 'package:ignis/src/nodes/transform_node.dart';
import 'package:ignis/src/shape.dart';

class ShapeNode extends TransformNode {
  /// Controls the geometry drawn, scaled to this node's `size`.
  Shape shape;

  /// Passed to the canvas when drawing the shape.
  final Paint paint;

  ShapeNode({
    required this.shape,
    Paint? paint,
    super.position,
    super.scale,
    super.angle,
    super.size,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : paint = paint ?? Paint();

  late Rect _dest;

  @override
  void renderTransformed(Canvas canvas) {
    _dest = shape.rect(size);

    switch (shape) {
      case .circle:
        canvas.drawOval(_dest, paint);

      case .rectangle:
        canvas.drawRect(_dest, paint);
    }
  }

  @override
  void debugRenderTransformed(Canvas canvas) {
    super.debugRenderTransformed(canvas);
    canvas.drawRect(_dest, DEBUG_TRANSFORM_PAINT);
  }
}
