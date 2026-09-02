// SPDX-AI-Disclosure: none

import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:ignis/src/effects/nodes/transition_effect.dart';

/// Fades [color] in, swaps, then fades [color] back out.
class CurtainTransitionEffect extends TransitionEffect {
  /// The color faded through. Defaults to black.
  final Color color;

  @override
  final double swapAt;

  final Paint _paint = Paint();

  CurtainTransitionEffect(
    super.to,
    super.from, {
    Color? color,
    double? duration,
    Curve? curve,
    double? swapAt,
    super.cleanup,
    super.enabled,
    super.priority,
  }) : color = color ?? const Color(0xFF000000),
       swapAt = swapAt ?? 0.5,
       super(controller: .duration(duration ?? 1, curve));

  @override
  void build() {
    super.build();
    _paint.color = color.withValues(alpha: 0);

    draw((canvas) {
      canvas.drawRect(Rect.largest, _paint);
    });
  }

  @override
  void apply(double progress) {
    final double alpha;

    if (progress < swapAt) {
      alpha = progress / swapAt;
    } else if (swapAt < 1) {
      alpha = 1 - (progress - swapAt) / (1 - swapAt);
    } else {
      alpha = 1;
    }

    _paint.color = color.withValues(alpha: clampDouble(alpha, 0, 1));
  }
}
