// SPDX-AI-Disclosure: none

import 'package:flutter/animation.dart';
import 'package:ignis/src/effects/nodes/transition_effect.dart';

/// Fades the incoming layer in over the still-painting outgoing side.
///
/// Use [crossFade] to additionally fade the outgoing side down.
class FadeTransitionEffect extends TransitionEffect {
  /// Whether the outgoing side fades down as the incoming one fades in.
  ///
  /// Defaults to false.
  final bool crossFade;

  @override
  double get swapAt => 0;

  FadeTransitionEffect(
    super.to,
    super.from, {
    double? duration,
    Curve? curve,
    bool? crossFade,
    super.cleanup,
    super.enabled,
    super.priority,
  }) : crossFade = crossFade ?? false,
       super(controller: .duration(duration ?? 1, curve));

  @override
  void apply(double progress) {
    to.opacity = progress;
    if (crossFade) from?.opacity = 1 - progress;
  }
}
