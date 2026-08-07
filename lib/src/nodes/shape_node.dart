import 'dart:ui';

import 'package:ignis/src/debug.dart';
import 'package:ignis/src/nodes/sized_node.dart';
import 'package:ignis/src/shape.dart';

class ShapeNode extends SizedNode {
  /// Controls the geometry drawn.
  Shape shape;

  /// Passed to the canvas when drawing the shape.
  final Paint paint;

  ShapeNode({
    required this.shape,
    Paint? paint,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : paint = paint ?? Paint();

  @override
  double get width => shape.width;

  @override
  double get height => shape.height;

  late Rect _dest;

  @override
  void renderAnchored(Canvas canvas) {
    _dest = shape.rect();

    switch (shape) {
      case Circle():
        canvas.drawOval(_dest, paint);

      case Rectangle():
        canvas.drawRect(_dest, paint);
    }
  }

  @override
  void debugRenderAnchored(Canvas canvas) {
    canvas.drawRect(_dest, DEBUG_TRANSFORM_PAINT);
  }
}
