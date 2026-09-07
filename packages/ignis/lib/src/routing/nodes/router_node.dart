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
/// settle the running navigation first, except that a [pop] during the push it
/// matches turns that push around instead. Usually, settling means instantly
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
    super.children,
  }) : transition = transition ?? CutTransition(),
       super(inherit: .scene);

  @override
  void build() {
    super.build();
    _arrange();

    tick((dt) {
      _arrange();
      final navigation = _navigation;
      if (navigation == null) return;

      // The route added only reaches the tree at the next flush.
      if (!navigation.incoming.isMounted) return;

      if (navigation.step(dt)) {
        _settle();
        return;
      }

      navigation.pose();
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
    final outgoing = top;

    // Nothing to leave, so the route simply stands.
    if (outgoing == null) {
      _place(route);
      return Future.value();
    }

    return _launch(
      _Swap(
        transition ?? route.transition ?? this.transition,
        settled: Completer<void>(),
        incoming: route,
        outgoing: outgoing,
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
    final covered = top;

    // Nothing to cover, so the route simply stands.
    if (covered == null) {
      _place(route);
    } else {
      _launch(
        _Layer(
          route.transition ?? transition,
          settled: Completer<void>(),
          incoming: route,
          covered: covered,
          backdrop: route.backdrop,
        ),
      );
    }

    // Set once launched, since settling a pop of this same route clears it.
    final completer = Completer<R?>();
    route._completer = completer;
    return completer.future;
  }

  /// Plays the top route's push back, uncovering the route beneath and
  /// completing the push with [result], which must be of the type it asked
  /// for. Completes once the navigation settles. Popping a push whose route
  /// has not reached the tree yet takes it back. Throws a [StateError] on a
  /// stack of one, or while a [go] runs, since a go leaves one route.
  Future<void> pop([Object? result]) {
    final navigation = _navigation;
    if (navigation is _Swap) throw StateError('Cannot pop the last route.');

    if (navigation is _Layer) {
      // Popping the push still in flight plays it back rather than settling it.
      if (navigation.turn()) {
        final incoming = navigation.incoming;
        incoming._complete(result);

        // Taken back before its route reached the tree, so it never happened.
        if (!incoming.isMounted) _settle();
        return navigation.settled.future;
      }

      // Settling a running pop takes its route off the stack, so the stack is
      // read after.
      _settle();
    }

    final stack = routes;
    if (stack.length <= 1) throw StateError('Cannot pop the last route.');
    final leaving = stack.last;
    leaving._complete(result);

    return _launch(
      _Layer(
        leaving.transition ?? transition,
        settled: Completer<void>(),
        incoming: leaving,
        covered: stack.elementAt(stack.length - 2),
        backdrop: leaving.backdrop,
        forward: false,
      ),
    );
  }

  /// Places [route] above the stack.
  void _place(RouteNode route) {
    route.priority = _above;
    add(route);
  }

  /// Starts [navigation]: its route placed above the stack, its chrome above
  /// that, and its clock at the end it runs from. The tick poses it from there
  /// once its route is in the tree.
  Future<void> _launch(_Navigation navigation) {
    _navigation = navigation;
    final incoming = navigation.incoming;
    _place(incoming);

    navigation.transition.chrome
      ?..priority = incoming.priority + 1
      ..attach(this);

    navigation.start();
    _arrange();
    return navigation.settled.future;
  }

  /// Ends the running navigation, if one is, taking whichever routes it left
  /// off the stack.
  ///
  /// When the clock has landed, posing once more is what finishes the
  /// transition: the tick that lands it settles instead of posing, and nothing
  /// else returns the chrome to rest. Settled early, the sides are simply
  /// returned to rest.
  void _settle() {
    final navigation = _navigation;
    if (navigation == null) return;
    _navigation = null;
    final incoming = navigation.incoming;

    // A route that never reached the tree was never on the stack.
    if (!incoming.isMounted) {
      incoming._complete(null);
      remove(incoming);
    } else {
      navigation
        ..pose()
        ..rest();

      for (final route in navigation.leaving(routes).toList(growable: false)) {
        _retire(route);
      }

      _order();
    }

    navigation
      ..transition.chrome?.detach()
      ..settled.complete();

    _arrange();
  }

  /// What [route] takes part in right now, given the [covering] route above
  /// it or null when it is the top: a side of the running navigation takes
  /// what its transition names for that side, a covered one is in its
  /// backdrop's running state, the top is live, and one beneath is in the
  /// settled state of the backdrop above it.
  Activity _activityOf(RouteNode route, RouteNode? covering) {
    final side = _navigation?.activityOf(route);
    if (side != null) return side;
    if (covering == null) return .all;
    return covering.backdrop.settled & ~Activity.input;
  }

  /// Gives every route on the stack what it takes part in.
  ///
  /// Writing [Node.activity] never reorders the egg, so the stack is safe to
  /// walk while it is being written to.
  void _arrange() {
    final stack = routes;
    final last = stack.length - 1;

    for (final (index, route) in stack.indexed) {
      route.activity = _activityOf(route, index == last ? null : stack.elementAt(index + 1));
    }
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
    remove(route);
  }
}
