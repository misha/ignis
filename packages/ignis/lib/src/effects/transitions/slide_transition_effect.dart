// SPDX-AI-Disclosure: none

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart' show AxisDirection;
import 'package:ignis/src/effects/nodes/transition_effect.dart';
import 'package:ignis/src/math.dart';

/// Slides the incoming side in and the outgoing side out, as if being shoved.
///
/// Wired without a `from`, the outgoing side stands still and the incoming one
/// slides over it instead.
class SlideTransitionEffect extends TransitionEffect {
  /// The direction the incoming side travels. Defaults to [AxisDirection.up].
  final AxisDirection direction;

  @override
  double get swapAt => 0;

  final MVector2 _size = .zero();

  SlideTransitionEffect(
    super.to,
    super.from, {
    AxisDirection? direction,
    double? duration,
    Curve? curve,
    super.cleanup,
    super.enabled,
    super.priority,
  }) : direction = direction ?? .up,
       super(controller: .duration(duration ?? 1, curve));

  @override
  void build() {
    super.build();

    // TODO: Doesn't seem right.
    onSceneResize((size) {
      _size.setFrom(size);
    });
  }

  @override
  void apply(double progress) {
    final to = this.to.position;
    final from = this.from?.position;
    final remaining = 1 - progress;

    switch (direction) {
      case .up:
        to.setValues(0, remaining * _size.y);
        from?.setValues(0, -progress * _size.y);

      case .down:
        to.setValues(0, -remaining * _size.y);
        from?.setValues(0, progress * _size.y);

      case .left:
        to.setValues(remaining * _size.x, 0);
        from?.setValues(-progress * _size.x, 0);

      case .right:
        to.setValues(-remaining * _size.x, 0);
        from?.setValues(progress * _size.x, 0);
    }
  }
}
