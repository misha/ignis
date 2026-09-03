// SPDX-AI-Disclosure: ai-generated

import 'package:flutter/foundation.dart';
import 'package:ignis/src/nodes/opacity_node.dart';
import 'package:ignis/src/routing/nodes/router_node.dart';

/// One of the routes a [RouterNode] shows.
///
/// Must always be placed as a direct child of a [RouterNode].
///
/// Its transform, opacity, activity, and priority belong to the router.
class RouteNode<T> extends OpacityNode {
  /// The name a navigation reaches this route by.
  final T name;

  RouteNode({
    required this.name,
    super.children,
  });

  @override
  void build() {
    super.build();
    final host = parent;

    // TODO: Maybe needs a `strict` parameter.
    if (host is! RouterNode<T>) {
      throw StateError('RouteNode must be a direct child of a RouterNode<$T>.');
    }

    host.router.add(this);
    trash(() => host.router.remove(this));
  }

  /// Returns this route to how it stands outside a navigation.
  @internal
  void reset() {
    position.setZero();
    scale.splat(1);
    angle = 0;
    opacity = 1;
  }
}
