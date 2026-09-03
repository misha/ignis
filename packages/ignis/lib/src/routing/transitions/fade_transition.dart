// SPDX-AI-Disclosure: none

import 'package:flutter/animation.dart';
import 'package:ignis/src/routing/transition.dart';

/// Fades the incoming side in over the still-painting outgoing one.
///
/// [crossFade] also fades the outgoing side down.
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
       super(timeline: .duration(duration ?? 1, curve));

  @override
  void apply(progress, incoming, outgoing) {
    incoming.opacity = progress;
    if (crossFade) outgoing?.opacity = 1 - progress;
  }
}
