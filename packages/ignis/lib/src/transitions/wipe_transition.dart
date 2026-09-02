// SPDX-AI-Disclosure: ai-generated

import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart' show AxisDirection;
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/transition_group_node.dart';
import 'package:ignis/src/transition.dart';

/// A hard-edged panel sweeps in from the leading edge to full cover, trades
/// the sides, then exits the trailing edge.
class WipeTransition extends Transition {
  /// The direction the panel travels. Defaults to [AxisDirection.right].
  final AxisDirection direction;

  /// The panel's color. Defaults to black.
  final Color color;

  /// The progress at which the sides trade places. Defaults to 0.5.
  final double swapAt;

  final Paint _paint = Paint();

  WipeTransition({
    AxisDirection? direction,
    Color? color,
    double? duration,
    Curve? curve,
    double? swapAt,
  }) : direction = direction ?? .right,
       color = color ?? const Color(0xFF000000),
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
    final covering = progress < swapAt;
    final double sweep;

    if (covering) {
      sweep = progress / swapAt;
    } else if (swapAt < 1) {
      sweep = (progress - swapAt) / (1 - swapAt);
    } else {
      sweep = 1;
    }

    final w = size.x;
    final h = size.y;

    _paint.color = color;

    final panel = switch (direction) {
      .right =>
        covering //
            ? Rect.fromLTRB(0, 0, sweep * w, h)
            : Rect.fromLTRB(sweep * w, 0, w, h),
      .left =>
        covering //
            ? Rect.fromLTRB(w - sweep * w, 0, w, h)
            : Rect.fromLTRB(0, 0, w - sweep * w, h),
      .down =>
        covering //
            ? Rect.fromLTRB(0, 0, w, sweep * h)
            : Rect.fromLTRB(0, sweep * h, w, h),
      .up =>
        covering //
            ? Rect.fromLTRB(0, h - sweep * h, w, h)
            : Rect.fromLTRB(0, 0, w, h - sweep * h),
    };

    canvas.drawRect(panel, _paint);
  }
}
