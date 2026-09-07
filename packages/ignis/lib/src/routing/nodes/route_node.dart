// SPDX-AI-Disclosure: ai-generated

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:ignis/src/nodes/opacity_node.dart';
import 'package:ignis/src/routing/backdrop.dart';
import 'package:ignis/src/routing/nodes/router_node.dart';
import 'package:ignis/src/routing/transition.dart';

/// One entry on a [RouterNode]'s stack.
///
/// Its transform, opacity, activity, and priority belong to the router.
class RouteNode extends OpacityNode {
  /// What the route beneath takes part in while this one covers it.
  ///
  /// Defaults to a frozen backdrop.
  final Backdrop backdrop;

  /// The transition to play when this route arrives.
  ///
  /// It is also played in reverse when route leaves.
  ///
  /// Null falls back to the router's default transition. Some router operations
  /// can also override this transition.
  final Transition? transition;

  /// What the push that laid this route down is waiting on, if a push did.
  @internal
  Completer<Object?>? completer;

  RouteNode({
    Backdrop? backdrop,
    this.transition,
    super.children,
  }) : backdrop = backdrop ?? const .frozen();

  /// Returns this route to how it stands outside a navigation.
  @internal
  void reset() {
    position.setZero();
    scale.splat(1);
    angle = 0;
    opacity = 1;
  }
}
