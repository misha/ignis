// SPDX-AI-Disclosure: ai-generated

import 'dart:ui';

import 'package:ignis/src/effects/effect_controller.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/transition_group_node.dart';

/// The style and clock of one swap between two transition groups.
///
/// A transition never enters the tree. Its host, a `TransitionNode`, drives
/// [controller] and asks for the pose at each progress, so both sides are a
/// pure function of progress and a swap runs forward and reverse freely, at
/// any moment.
abstract class Transition {
  /// This transition's clock, driven by the hosting `TransitionNode`.
  final EffectController controller;

  Transition({required this.controller});

  /// Poses both sides at [progress] by writing onto the groups. Runs once when
  /// the swap starts and once per tick after the clock moves, so rendering
  /// always sees the pose. [size] is the scene's.
  void apply(
    double progress,
    Vector2 size, {
    required TransitionGroupNode incoming,
    required TransitionGroupNode outgoing,
  }) {}

  /// Paints this transition's own visuals, above the host's whole subtree.
  void paintChrome(Canvas canvas, double progress, Vector2 size) {}
}
