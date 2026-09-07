// SPDX-AI-Disclosure: ai-assisted

import 'dart:async';

import 'package:ignis/src/core.dart';
import 'package:ignis/src/nodes/opacity_node.dart';
import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/routing/backdrop.dart';
import 'package:ignis/src/routing/transition.dart';
import 'package:ignis/src/routing/transitions/cut_transition.dart';

part 'navigation.dart';
part 'route_node.dart';

/// A stack of [RouteNode]s.
///
/// The [RouteNode] children *are* the stack, bottom to top. The operations are:
///
///   - [go] replaces the entire stack with its route.
///   - [push] adds a route to the top of the stack.
///   - [pop] removes a route from the top of the stack.
///
/// Leaving the router is equivalent to leaving the tree, so nodes may use the
/// usual `build` or mount signals to respond to routing operations. Note that
/// the router doesn't know how to build routes, nor does it keep a registry of
/// them. It's up to the programmer to standardize how their routes are made -
/// or not, if that's the shape of the game.
///
/// And now, some quirks!
///
/// **Scheduling**
///
/// Routing is slightly tricky because added nodes only hit a tree on the next
/// frame. As a result, a [push] or [go] begins at the call but holds until its
/// route is in the tree, so nothing moves before the *next* frame, even if the
/// router itself has yet to update. A [pop] starts at the call, since its route
/// is already in the tree.
///
/// **Region**
///
/// The region routed is the [shape] in effect above this node, or the scene's
/// when nothing spatial is above. The routes and any transition chrome will
/// fill that region. This is notable because the "natural" usage of a router,
/// to control the high-level view of the game, works off scene size by default.
///
/// Additionally, this implementation means you can "route" any subregion of the
/// canvas. Previous versions of the code even called it a `TransitionNode`,
/// because by declaring a sized `SpatialNode` parent, you can create arbitrary
/// transitioning subregions of your game. Think of a HUD that animates between
/// town and combat displays: it's just routing between the two, and you have
/// the entire power of [Transition] to control exactly how the two switch.
///
/// **Concurrent Navigation**
///
/// When navigating while another navigation is already running, the router will
/// settle the running navigation first, except that a [pop] during a running
/// navigation plays it back instead. Usually, settling means instantly
/// finishing that transition to start the new one. Although this doesn't look
/// great, it's somewhat mitigated by the fact that transitions can be made
/// quite short, so the snapping is less noticeable; and most games don't let
/// you switch routes multiple times a second anyway, so the instant finish does
/// not realistically trigger.
class RouterNode extends SpatialNode {
  /// The transition a navigation plays when it names none.
  ///
  /// Defaults to a [CutTransition].
  final Transition transition;

  /// The stack, bottom to top.
  late final Iterable<RouteNode> _routes = query<RouteNode>();

  /// The stack, bottom to top.
  ///
  /// A route taken off the stack is still a child until the next flush, so
  /// what is leaving is filtered out rather than waited on.
  Iterable<RouteNode> get routes => _routes.where((route) => !route.isRemoving);

  /// The route on top, or null while the stack is empty.
  RouteNode? get top => routes.lastOrNull;

  /// The priority that sits above every route on the stack.
  ///
  /// An arriving route is placed with this, and a navigation's chrome one
  /// above it, so the two never disagree about what "on top" means.
  int get _above => (top?.priority ?? -1) + 1;

  /// The running navigation, or null between navigations.
  _Navigation? _navigation;

  /// Whether a navigation is running.
  bool get isTransitioning => _navigation != null;

  /// The running navigation's progress, or 1 between navigations.
  double get progress => _navigation?.progress ?? 1;

  RouterNode({
    Transition? transition,
    super.shape,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    Iterable<RouteNode>? children,
  }) : transition = transition ?? CutTransition(),
       super(inherit: .scene) {
    RouteNode? beneath;

    for (final route in children ?? const <RouteNode>[]) {
      super.add(route);
      beneath?.activity = route.backdrop.settled & ~Activity.input;
      beneath = route;
    }

    beneath?.activity = .all;
  }

  /// Routes come and go through [push], [go], and [pop] alone.
  @override
  T add<T extends Node>(T node) {
    throw UnsupportedError('Routes come and go through push, go, and pop.');
  }

  /// Routes come and go through [push], [go], and [pop] alone.
  @override
  bool remove(Node node) {
    throw UnsupportedError('Routes come and go through push, go, and pop.');
  }

  @override
  void build() {
    super.build();

    tick((dt) {
      if (_navigation?.tick(dt) ?? false) {
        _settle();
      }
    });
  }

  /// Replaces the whole stack with [route], playing [transition] over the
  /// route's own and the default, and completes once the navigation settles.
  ///
  /// A navigation already running is settled first. Every push dropped
  /// completes with null.
  Future<void> go(
    RouteNode route, {
    Transition? transition,
  }) {
    _settle();

    // Checked after settling, since that is what takes the departing route
    // off the stack and so makes room to go back to it.
    assert(!routes.contains(route), 'That route is already on the stack.');

    return _launch(
      _Swap(
        transition ?? route.transition ?? this.transition,
        incoming: route,
        outgoing: top,
      ),
    );
  }

  /// Lays [route] over the top, playing the route's own transition over the
  /// default and leaving the route beneath to its `backdrop`.
  ///
  /// A push takes no transition of its own, because the matching [pop] has to
  /// play the same one back, and the route is where that is kept.
  ///
  /// Completes with what the [pop] carries, or null when a later navigation
  /// drops the push.
  Future<R?> push<R>(RouteNode route) {
    _settle();

    // Checked after settling, since that is what takes the departing route
    // off the stack and so makes room to go back to it.
    assert(!routes.contains(route), 'That route is already on the stack.');

    _launch(
      _Layer(
        route.transition ?? transition,
        incoming: route,
        covered: top,
        backdrop: route.backdrop,
      ),
    );

    // Set once launched, since settling a pop of this same route clears it.
    final completer = Completer<R?>();
    route._completer = completer;
    return completer.future;
  }

  /// Plays the running navigation back, or with none running, plays the top
  /// route's push back, uncovering the route beneath and completing that push
  /// with [result], which must be of the type it asked for. Completes once the
  /// navigation settles. Throws a [StateError] on an empty stack.
  Future<void> pop([Object? result]) {
    final navigation = _navigation;

    if (navigation != null && navigation.turn()) {
      final incoming = navigation.incoming;
      incoming._complete(result);

      // Taken back before its route reached the tree, so it never happened.
      if (!incoming.isMounted) _settle();
      return navigation.settled.future;
    }

    // Settling a running navigation takes what it leaves off the stack, so
    // the stack is read after.
    _settle();
    final stack = routes;
    if (stack.isEmpty) throw StateError('Nothing to pop.');
    final leaving = stack.last;
    leaving._complete(result);

    return _launch(
      _Layer(
        leaving.transition ?? transition,
        incoming: leaving,
        covered: stack.length > 1 ? stack.elementAt(stack.length - 2) : null,
        backdrop: leaving.backdrop,
        forward: false,
      ),
    );
  }

  /// Starts [navigation]: its route placed above the stack, and its chrome
  /// above that.
  Future<void> _launch(_Navigation navigation) {
    _navigation = navigation;
    final incoming = navigation.incoming;
    incoming.priority = _above;
    super.add(incoming);
    final chrome = navigation.transition.chrome;

    if (chrome != null) {
      chrome.priority = incoming.priority + 1;
      super.add(chrome);
    }

    return navigation.settled.future;
  }

  /// Ends the running navigation, if one is, taking whichever routes it left
  /// off the stack.
  void _settle() {
    final navigation = _navigation;
    if (navigation == null) return;
    _navigation = null;

    // A route that never reached the tree is played back out.
    if (!navigation.incoming.isMounted) navigation.turn();
    navigation.settle();

    for (final route in navigation.leaving(routes).toList(growable: false)) {
      _retire(route);
    }

    _order();
    final chrome = navigation.transition.chrome;
    if (chrome != null) super.remove(chrome);
  }

  /// Numbers the stack bottom to top, so a route's priority is its place on
  /// it and nothing climbs across navigations.
  void _order() {
    for (final (index, route) in routes.indexed) {
      route.priority = index;
    }
  }

  /// Takes [route] off the stack, dropping the push that laid it there.
  void _retire(RouteNode route) {
    route._complete(null);
    route.disable();
    super.remove(route);
  }
}
