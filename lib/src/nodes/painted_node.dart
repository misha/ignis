import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:ignis/src/nodes/sized_node.dart';
import 'package:ignis/src/palette.dart';

abstract class PaintedNode extends SizedNode {
  /// This node's registered paints.
  final Palette palette;

  /// The default paint.
  Paint get paint => palette.paint;

  PaintedNode({
    Paint? paint,
    super.anchor,
    super.position,
    super.scale,
    super.angle,
    super.enabled,
    super.priority,
    super.children,
  }) : palette = Palette(paint: paint);

  @override
  void renderAnchored(Canvas canvas) {
    for (final entry in palette.entries) {
      if (!entry.enabled) continue;
      final offset = entry.offset;
      // TODO: Profile the different ways to do this.
      final hasOffset = !offset.isZero;
      if (hasOffset) canvas.translate(offset.x, offset.y);
      renderPainted(canvas, entry.paint);
      if (hasOffset) canvas.translate(-offset.x, -offset.y);
    }
  }

  /// Called once for each paint in the [palette].
  @visibleForOverriding
  void renderPainted(Canvas canvas, Paint paint);
}
