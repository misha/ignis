// SPDX-AI-Disclosure: ai-generated

import 'package:ignis/src/core.dart';
import 'package:ignis/src/routing/nodes/route_node.dart';
import 'package:ignis/src/timeline.dart';

/// The style and clock of one navigation between two routes.
///
/// A transition never enters the tree. Its host, a `RouterNode`, drives
/// [timeline], asks for the pose at each progress, and mounts [chrome] for
/// the length of the navigation. Both sides are a pure function of progress, so a
/// navigation runs forward and reverse freely, at any moment.
abstract class Transition {
  /// This transition's clock, driven by the hosting `RouterNode`.
  final Timeline timeline;

  /// This transition's own visuals, mounted above the host's whole subtree
  /// for the length of the navigation. Null for none.
  Node? get chrome => null;

  Transition({
    required this.timeline,
  });

  /// Poses both sides at [progress] by writing onto the routes, whose size is
  /// the region being routed. [outgoing] is null on a push, where nothing is
  /// leaving. Runs once when the navigation starts and once per tick after the
  /// clock moves, so rendering always sees the pose.
  void apply(double progress, RouteNode incoming, RouteNode? outgoing);
}
