// SPDX-AI-Disclosure: ai-generated

import 'package:ignis/src/core.dart';
import 'package:ignis/src/nodes/transition_group_node.dart';
import 'package:ignis/src/timeline.dart';

/// The style and clock of one swap between two transition groups.
///
/// A transition never enters the tree. Its host, a `TransitionNode`, drives
/// [timeline], asks for the pose at each progress, and mounts [chrome] for
/// the length of the swap. Both sides are a pure function of progress, so a
/// swap runs forward and reverse freely, at any moment.
abstract class Transition {
  /// This transition's clock, driven by the hosting `TransitionNode`.
  final Timeline timeline;

  /// This transition's own visuals, mounted above the host's whole subtree
  /// for the length of the swap. Null for none.
  Node? get chrome => null;

  Transition({required this.timeline});

  /// Poses both sides at [progress] by writing onto the groups, whose size is
  /// the region being swapped. Runs once when the swap starts and once per
  /// tick after the clock moves, so rendering always sees the pose.
  void apply(double progress, TransitionGroupNode incoming, TransitionGroupNode outgoing) {}
}
