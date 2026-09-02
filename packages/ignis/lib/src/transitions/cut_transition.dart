// SPDX-AI-Disclosure: none

import 'package:ignis/src/transition.dart';

/// Swaps instantly with no visuals, finishing on the first tick.
class CutTransition extends Transition {
  CutTransition() : super(controller: .terminal());

  @override
  void apply(_, _, outgoing) {
    outgoing.opacity = 0;
  }
}
