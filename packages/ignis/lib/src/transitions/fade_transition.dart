// SPDX-AI-Disclosure: ai-generated

import 'package:flutter/animation.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/transition_group_node.dart';
import 'package:ignis/src/transition.dart';

/// Fades the incoming side in over the still-painting outgoing one.
///
/// The plain fade is one layer and expects the incoming group to paint above
/// the outgoing one. [crossFade] also fades the outgoing side down, which
/// works in either order.
class FadeTransition extends Transition {
  /// Whether the outgoing side fades down as the incoming one fades in.
  ///
  /// Defaults to false.
  final bool crossFade;

  FadeTransition({
    double? duration,
    Curve? curve,
    bool? crossFade,
  }) : crossFade = crossFade ?? false,
       super(controller: .duration(duration ?? 1, curve));

  @override
  void apply(
    double progress,
    Vector2 size, {
    required TransitionGroupNode incoming,
    required TransitionGroupNode outgoing,
  }) {
    incoming.opacity = progress;
    if (crossFade) outgoing.opacity = 1 - progress;
  }
}
