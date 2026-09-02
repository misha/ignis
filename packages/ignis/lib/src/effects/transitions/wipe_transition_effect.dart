// SPDX-AI-Disclosure: none

import 'dart:ui';

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart' show AxisDirection;
import 'package:ignis/src/effects/nodes/transition_effect.dart';
import 'package:ignis/src/math.dart';

/// A hard-edged panel sweeps in from the leading edge to full cover, swaps,
/// then exits the trailing edge.
class WipeTransitionEffect extends TransitionEffect {
  /// The direction the panel travels. Defaults to [AxisDirection.right].
  final AxisDirection direction;

  /// The panel's color. Defaults to black.
  final Color color;

  @override
  final double swapAt;

  final Paint _paint = Paint();
  final MVector2 _size = .zero();
  Rect _panel = .zero;

  WipeTransitionEffect(
    super.to,
    super.from, {
    AxisDirection? direction,
    Color? color,
    double? duration,
    Curve? curve,
    double? swapAt,
    super.cleanup,
    super.enabled,
    super.priority,
  }) : direction = direction ?? .right,
       color = color ?? const Color(0xFF000000),
       swapAt = swapAt ?? 0.5,
       super(controller: .duration(duration ?? 1, curve));

  @override
  void build() {
    super.build();
    _paint.color = color;
    _panel = Rect.zero;

    // TODO: Doesn't seem right.
    onSceneResize((size) {
      _size.setFrom(size);
    });

    draw((canvas) {
      canvas.drawRect(_panel, _paint);
    });
  }

  @override
  void apply(double progress) {
    final covering = progress < swapAt;
    final double sweep;

    if (covering) {
      sweep = progress / swapAt;
    } else if (swapAt < 1) {
      sweep = (progress - swapAt) / (1 - swapAt);
    } else {
      sweep = 1;
    }

    final w = _size.x;
    final h = _size.y;

    _panel = switch (direction) {
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
  }
}
