// SPDX-AI-Disclosure: ai-generated

import 'package:flutter/animation.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/nodes/opacity_node.dart';
import 'package:ignis/src/routing/transition.dart';

/// Fades through a [veil] above everything, its opacity ramping to 1 at
/// [swapAt] and back to 0 after, trading the sides under full cover.
///
/// The veil fills the region swapped, so a shape-less `ShapeNode` makes a
/// solid curtain.
class CurtainTransition extends Transition {
  /// What is faded through.
  final Node veil;

  /// The progress at which the sides trade places. Defaults to 0.5.
  final double swapAt;

  @override
  late final OpacityNode chrome = .new(children: [veil]);

  CurtainTransition({
    required this.veil,
    double? duration,
    Curve? curve,
    double? swapAt,
  }) : swapAt = swapAt ?? 0.5,
       super(timeline: .duration(duration ?? 1, curve));

  @override
  void apply(progress, incoming, outgoing) {
    final covering = progress < swapAt;
    incoming.opacity = covering ? 0 : 1;
    outgoing?.opacity = covering ? 1 : 0;

    if (covering) {
      chrome.opacity = progress / swapAt;
    } else if (swapAt < 1) {
      chrome.opacity = 1 - (progress - swapAt) / (1 - swapAt);
    } else {
      chrome.opacity = 1;
    }
  }
}
