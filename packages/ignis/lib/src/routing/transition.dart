// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
import 'package:ignis/src/routing/nodes/route_node.dart';
import 'package:ignis/src/timeline.dart';

/// Describes a navigation between two routes.
///
/// A transition is not a node, but rather a specification for an operation.
/// Instead, a `Router` drives the [timeline], periodically asking for the pose.
/// If the transition has [chrome], the router also mounts it for the duration
/// of the navigation, allowing it to be posed as well.
///
/// Transitions are intended to be reusable and reversible. Keep these
/// requirements in mind when implementing a custom [apply].
abstract class Transition {
  /// This transition's clock, driven by a `Router`.
  final Timeline timeline;

  /// This transition's own visuals, mounted above the host's whole subtree
  /// for the length of the navigation. Null for none.
  Node? get chrome => null;

  Transition({
    required this.timeline,
  });

  /// Poses both sides at [progress] by writing onto the routes, whose size is
  /// the region being routed. [outgoing] is null on a push, where nothing is
  /// leaving and the covered route is its `Backdrop`'s to pose. Runs once when
  /// the navigation starts and once per tick after the clock moves, so
  /// rendering always sees the pose.
  void apply(double progress, RouteNode incoming, RouteNode? outgoing);
}
