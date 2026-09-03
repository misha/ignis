// SPDX-AI-Disclosure: ai-generated

import 'package:flutter/foundation.dart';
import 'package:ignis/src/nodes/opacity_node.dart';
import 'package:ignis/src/routing/nodes/router_node.dart';
import 'package:ignis/src/routing/router.dart';

/// One of the routes a [RouterNode] shows.
///
/// Must always be placed as a direct child of a [RouterNode].
///
/// Its transform, opacity, activity, and priority belong to the router.
class RouteNode<T> extends OpacityNode {
  /// The name a navigation reaches this route by.
  final T name;

  /// Whether building anywhere but directly under a [RouterNode] throws a
  /// [StateError]. Defaults to true.
  bool strict;

  RouteNode({
    required this.name,
    bool? strict,
    super.children,
  }) : strict = strict ?? true;

  @override
  void build() {
    super.build();
    final router = readOrNull<Router<T>>();

    if (router == null || parent is! RouterNode<T>) {
      if (strict) {
        throw StateError('RouteNode must be a direct child of a RouterNode<$T>.');
      } else {
        return;
      }
    }

    router.add(this);
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
