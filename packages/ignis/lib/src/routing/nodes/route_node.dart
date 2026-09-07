// SPDX-AI-Disclosure: ai-generated

part of 'router_node.dart';

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
  /// It is also played in reverse when the route is popped.
  ///
  /// Null falls back to the router's default transition. Some router operations
  /// can also override this transition.
  final Transition? transition;

  /// What the push that laid this route down is waiting on, if a push did.
  Completer<Object?>? _completer;

  RouteNode({
    Backdrop? backdrop,
    this.transition,
    super.children,
  }) : backdrop = backdrop ?? const .frozen();

  /// Completes the push that laid this route down, if one is waiting, and
  /// forgets it.
  void _complete(Object? result) {
    _completer?.complete(result);
    _completer = null;
  }

  /// Returns this route to how it stands outside a navigation.
  void _reset() {
    position.setZero();
    scale.splat(1);
    angle = 0;
    opacity = 1;
  }
}
