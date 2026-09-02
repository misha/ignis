// SPDX-AI-Disclosure: none

import 'package:flutter/animation.dart';
import 'package:flutter/painting.dart' show AxisDirection;
import 'package:ignis/src/core.dart';
import 'package:ignis/src/nodes/opacity_node.dart';
import 'package:ignis/src/transition.dart';

/// A hard-edged [panel] sweeps in from the leading edge to full cover, trades
/// the sides, then exits the trailing edge.
class WipeTransition extends Transition {
  /// The direction the panel travels. Defaults to [AxisDirection.right].
  final AxisDirection direction;

  /// What sweeps across.
  final Node panel;

  /// The progress at which the sides trade places. Defaults to 0.5.
  final double swapAt;

  @override
  late final OpacityNode chrome = .new(children: [panel]);

  WipeTransition({
    required this.panel,
    AxisDirection? direction,
    double? duration,
    Curve? curve,
    double? swapAt,
  }) : direction = direction ?? .right,
       swapAt = swapAt ?? 0.5,
       super(timeline: .duration(duration ?? 1, curve));

  @override
  void apply(progress, incoming, outgoing) {
    final covering = progress < swapAt;
    incoming.opacity = covering ? 0 : 1;
    outgoing.opacity = covering ? 1 : 0;

    final double sweep;

    if (covering) {
      sweep = progress / swapAt;
    } else if (swapAt < 1) {
      sweep = (progress - swapAt) / (1 - swapAt);
    } else {
      sweep = 1;
    }

    final size = incoming.size;
    final width = size.x;
    final height = size.y;
    final position = chrome.position;

    switch (direction) {
      case .right:
        position.setValues(covering ? (sweep - 1) * width : sweep * width, 0);

      case .left:
        position.setValues(covering ? width - sweep * width : -sweep * width, 0);

      case .down:
        position.setValues(0, covering ? (sweep - 1) * height : sweep * height);

      case .up:
        position.setValues(0, covering ? height - sweep * height : -sweep * height);
    }
  }
}
