// SPDX-AI-Disclosure: none

import 'package:ignis/src/effects/nodes/transition_effect.dart';

/// Swaps instantly with no visuals, finishing on the first tick.
class CutTransitionEffect extends TransitionEffect {
  CutTransitionEffect(
    super.to,
    super.from, {
    super.cleanup,
    super.enabled,
    super.priority,
  }) : super(controller: .terminal());

  @override
  double get swapAt => 0;

  @override
  void apply(double progress) {
    // Nothing to do.
  }
}
