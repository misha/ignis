// SPDX-AI-Disclosure: ai-generated

import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/transition_group_node.dart';
import 'package:ignis/src/transition.dart';

/// Swaps instantly with no visuals, finishing on the first tick.
class CutTransition extends Transition {
  CutTransition() : super(controller: .terminal());

  @override
  void apply(
    double progress,
    Vector2 size, {
    required TransitionGroupNode incoming,
    required TransitionGroupNode outgoing,
  }) {
    outgoing.opacity = 0;
  }
}
