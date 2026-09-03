// SPDX-AI-Disclosure: none

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart' show AxisDirection;
import 'package:ignis/src/routing/transition.dart';

/// Slides the incoming side in and the outgoing side out, as if being shoved.
class SlideTransition extends Transition {
  /// The direction the incoming side travels. Defaults to [AxisDirection.up].
  final AxisDirection direction;

  SlideTransition({
    AxisDirection? direction,
    double? duration,
    Curve? curve,
  }) : direction = direction ?? .up,
       super(timeline: .duration(duration ?? 1, curve));

  @override
  void apply(progress, incoming, outgoing) {
    final size = incoming.size;
    final remaining = 1 - progress;

    switch (direction) {
      case .up:
        incoming.position.setValues(0, remaining * size.y);
        outgoing?.position.setValues(0, -progress * size.y);

      case .down:
        incoming.position.setValues(0, -remaining * size.y);
        outgoing?.position.setValues(0, progress * size.y);

      case .left:
        incoming.position.setValues(remaining * size.x, 0);
        outgoing?.position.setValues(-progress * size.x, 0);

      case .right:
        incoming.position.setValues(-remaining * size.x, 0);
        outgoing?.position.setValues(progress * size.x, 0);
    }
  }
}
