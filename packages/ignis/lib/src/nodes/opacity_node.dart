// SPDX-AI-Disclosure: none

import 'dart:ui';

import 'package:ignis/src/nodes/spatial_node.dart';

/// Fades its subtree as one image.
class OpacityNode extends SpatialNode {
  Paint? _paint;

  /// This subtree's opacity, 0 to 1. Defaults to 1.
  ///
  /// At 1 the subtree renders plainly, and at 0 it skips rendering entirely. In
  /// both of these scenarios, there is no performance cost.
  ///
  /// When opacity is *between* 0 and 1, the subtree is wrapped in a special
  /// canvas operation, `saveLayer`, fading it as one image. However, `saveLayer`
  /// is extraordinarily expensive with respect to performance, so this parameter
  /// must only be used for effects that truly require them, like transitions,
  /// fades, and dims.
  ///
  /// For handling the opacity of a single sprite, use `Paint`'s alpha channel
  /// directly, or take advantage of effects like `ColorOpacityEffect` and
  /// `ColorFilterOpacityEffect` to control alpha over time.
  double get opacity => _paint?.color.a ?? 1;

  set opacity(double value) {
    if (_paint == null && value >= 1) return;
    final paint = _paint ??= Paint();
    paint.color = paint.color.withValues(alpha: clampDouble(value, 0, 1));
  }

  OpacityNode({
    double? opacity,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) {
    if (opacity != null) {
      this.opacity = opacity;
    }
  }

  @override
  void render(Canvas canvas) {
    switch (opacity) {
      case <= 0:
        return;

      case >= 1:
        super.render(canvas);

      default:
        canvas.saveLayer(null, _paint!);
        super.render(canvas);
        canvas.restore();
    }
  }
}
