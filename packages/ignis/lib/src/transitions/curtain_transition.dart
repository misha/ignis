// SPDX-AI-Disclosure: ai-generated

import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/transition_group_node.dart';
import 'package:ignis/src/transition.dart';

/// Fades through a [color]: one veil above everything, its alpha ramping to 1
/// at [swapAt] and back to 0 after, trading the sides under full cover.
class CurtainTransition extends Transition {
  /// The color faded through. Defaults to black.
  final Color color;

  /// The progress at which the sides trade places. Defaults to 0.5.
  final double swapAt;

  final Paint _veil = Paint();

  CurtainTransition({
    Color? color,
    double? duration,
    Curve? curve,
    double? swapAt,
  }) : color = color ?? const Color(0xFF000000),
       swapAt = swapAt ?? 0.5,
       super(controller: .duration(duration ?? 1, curve));

  @override
  void apply(
    double progress,
    Vector2 size, {
    required TransitionGroupNode incoming,
    required TransitionGroupNode outgoing,
  }) {
    final covering = progress < swapAt;
    incoming.opacity = covering ? 0 : 1;
    outgoing.opacity = covering ? 1 : 0;
  }

  @override
  void paintChrome(Canvas canvas, double progress, Vector2 size) {
    final double alpha;

    if (progress < swapAt) {
      alpha = progress / swapAt;
    } else if (swapAt < 1) {
      alpha = 1 - (progress - swapAt) / (1 - swapAt);
    } else {
      alpha = 1;
    }

    _veil.color = color.withValues(alpha: clampDouble(alpha, 0, 1));
    canvas.drawRect(Rect.largest, _veil);
  }
}
