// SPDX-AI-Disclosure: ai-generated

import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/routing/nodes/route_node.dart';
import 'package:ignis/src/routing/router.dart';

/// Shows a [Router] with its [RouteNode] children: it ticks the router,
/// mounts the chrome of each navigation above the routes, and provides the
/// router to every node beneath it, which reads it with `read<Router<T>>()`.
///
/// The region routed is the [shape] in effect above this node, or the scene's
/// when nothing spatial is above, as a layout root takes it. The routes and
/// the chrome fill that region.
class RouterNode<T> extends SpatialNode {
  /// The router this node shows.
  final Router<T> router;

  RouterNode({
    required this.router,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : super(inherit: .scene) {
    // TODO: Allow for a default router, just like CollisionArenaNode.
    provide<Router<T>>(router);
  }

  @override
  void build() {
    super.build();

    router.onStart((transition) {
      final chrome = transition.chrome;
      if (chrome != null) add(chrome);
    });

    router.onSettle((transition) {
      final chrome = transition.chrome;
      if (chrome != null) remove(chrome);
    });

    tick(router.process);
  }
}
