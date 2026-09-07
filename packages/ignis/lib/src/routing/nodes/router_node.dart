// SPDX-AI-Disclosure: ai-assisted

import 'dart:async';

import 'package:ignis/src/core.dart';
import 'package:ignis/src/nodes/opacity_node.dart';
import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/routing/backdrop.dart';
import 'package:ignis/src/routing/transition.dart';
import 'package:ignis/src/routing/transitions/cut_transition.dart';
import 'package:yafsm/yafsm.dart' as fsm;

part 'route_node.dart';

final class _Machine extends fsm.Machine {
  /// The router isn't working on anything.
  late final isIdle = state('idle');

  /// A navigation has been scheduled. The router is waiting for it to hit the tree.
  late final isArriving = pstate<_Arrival>('arriving');

  /// A navigation is active. The router is actively processing it.
  late final isNavigating = pstate<_Navigation>('navigating');

  late final arrive = ptransition({isIdle}, isArriving);
  late final drop = transition({isArriving}, isIdle);
  late final stand = transition({isArriving}, isIdle);
  late final begin = ptransition({isArriving}, isNavigating);
  late final pop = ptransition({isIdle}, isNavigating);
  late final settle = transition({isNavigating}, isIdle);

  /// The running navigation, or null between navigations.
  _Navigation? get navigation => isNavigating() ? isNavigating.data : null;

  _Machine() {
    start(isIdle);
  }
}

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
/// frame. As a result, a [push] or [go] will always start on the *next* frame,
/// even if the router itself has yet to update. A [pop] starts at the call,
/// since its route is already in the tree.
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
  final Set<RouteNode> _retiring = .identity();

  /// The stack, bottom to top.
  ///
  /// A route taken off the stack is still a child until the next flush, so
  /// what is leaving is filtered out rather than waited on.
  Iterable<RouteNode> get routes {
    if (_retiring.isEmpty) return _routes;
    return _routes.where((route) => !_retiring.contains(route));
  }

  /// The route on top, or null while the stack is empty.
  RouteNode? get top => routes.lastOrNull;

  /// The priority that sits above every route on the stack.
  ///
  /// Both an arriving route and a navigation's chrome are placed with this,
  /// so the two never disagree about what "on top" means.
  int get _above => (top?.priority ?? -1) + 1;

  final _machine = _Machine();

  /// Whether a navigation is running.
  bool get isTransitioning => _machine.navigation != null;

  /// The running navigation's progress, or 1 between navigations.
  double get progress => _machine.navigation?.progress ?? 1;

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
       super(inherit: .scene) {
    _machine.isArriving.onEnter((arrival) {
      final route = arrival.route;
      route.priority = _above;
      add(route);
    });

    _machine.isNavigating.onEnter((navigation) {
      navigation
        ..start()
        ..pose();

      navigation.transition.chrome
        ?..priority = _above
        ..attach(this);
    });

    _machine.isNavigating.onExit((navigation) {
      navigation
        ..pose()
        ..rest();

      for (final route in navigation.leaving(routes).toList(growable: false)) {
        _retire(route);
      }

      _order();

      navigation
        ..transition.chrome?.detach()
        ..settled.complete();
    });

    _machine.stand.onTrigger((_, _) {
      final arrival = _machine.isArriving.data;
      arrival.settled.complete();
    });

    _machine.drop.onTrigger((_, _) {
      final arrival = _machine.isArriving.data;
      arrival.route._complete(null);
      remove(arrival.route);
      arrival.settled.complete();
    });

    _machine.onChange((_, _) {
      _arrange();
    });
  }

  @override
  void build() {
    super.build();
    _arrange();

    tick((dt) {
      // Whatever left last tick has flushed out of the tree by now.
      _retiring.clear();
      _arrange();

      if (_machine.isArriving()) {
        final arrival = _machine.isArriving.data;
        if (arrival.route.isMounted) _begin(arrival);
        return;
      }

      final navigation = _machine.navigation;
      if (navigation == null) return;

      if (navigation.step(dt)) {
        _machine.settle();
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
    return _arrive(route, transition, replace: true);
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
    final completer = Completer<R?>();
    _arrive(route, null, replace: false);

    // Set once arrived, since settling a pop of this same route clears it.
    route._completer = completer;
    return completer.future;
  }

  /// Plays the top route's push back, uncovering the route beneath and
  /// completing the push with [result], which must be of the type it asked
  /// for. Completes once the navigation settles. Popping a push that has not
  /// started yet takes it back. Throws a [StateError] on a stack of one, or
  /// while a [go] runs or arrives, since a go leaves one route.
  Future<void> pop([Object? result]) {
    final navigation = _machine.navigation;
    if (navigation is _Swap) throw StateError('Cannot pop the last route.');

    if (_machine.isArriving()) {
      final arrival = _machine.isArriving.data;
      if (arrival.replace) throw StateError('Cannot pop the last route.');
      arrival.route._complete(result);
      _machine.drop();
      return arrival.settled.future;
    }

    if (navigation is _Layer) {
      // Popping the push still in flight plays it back rather than settling it.
      if (navigation.turn()) {
        navigation.incoming._complete(result);
        return navigation.settled.future;
      }

      // Settling a running pop takes its route off the stack, so the stack is
      // read after.
      _machine.settle();
    }

    final stack = routes;
    if (stack.length <= 1) throw StateError('Cannot pop the last route.');
    final leaving = stack.last;
    leaving._complete(result);

    final layer = _Layer(
      leaving.transition ?? transition,
      settled: Completer<void>(),
      incoming: leaving,
      covered: stack.elementAt(stack.length - 2),
      backdrop: leaving.backdrop,
      forward: false,
    );

    _machine.pop(layer);
    return layer.settled.future;
  }

  /// Adds [route] and records it as the navigation to start once the tree has
  /// taken it, dropping whatever was arriving before it.
  Future<void> _arrive(
    RouteNode route,
    Transition? transition, {
    required bool replace,
  }) {
    _machine.drop();
    _machine.settle();

    // Checked after settling, since that is what takes the departing route
    // off the stack and so makes room to go back to it.
    assert(!routes.contains(route), 'That route is already on the stack.');

    final arrival = _Arrival(
      route,
      transition: transition,
      replace: replace,
      settled: Completer<void>(),
    );

    _machine.arrive(arrival);
    return arrival.settled.future;
  }

  /// Starts the arrival now that its route stands in the tree.
  void _begin(_Arrival arrival) {
    final route = arrival.route;
    final stack = routes;
    final covered = stack.length > 1 ? stack.elementAt(stack.length - 2) : null;

    // Nothing to cover or leave, so the route simply stands.
    if (covered == null) {
      _machine.stand();
      return;
    }

    if (!arrival.replace) {
      _machine.begin(
        _Layer(
          route.transition ?? transition,
          settled: arrival.settled,
          incoming: route,
          covered: covered,
          backdrop: route.backdrop,
        ),
      );

      return;
    }

    _machine.begin(
      _Swap(
        arrival.transition ?? route.transition ?? transition,
        settled: arrival.settled,
        incoming: route,
        outgoing: covered,
      ),
    );
  }

  /// What [route] takes part in right now, given the [covering] route above
  /// it or null when it is the top: a side of the running navigation takes
  /// what its transition names for that side, a covered one is in its
  /// backdrop's running state, the top is live, and one beneath is in the
  /// settled state of the backdrop above it.
  Activity _activityOf(RouteNode route, RouteNode? covering) {
    final side = _machine.navigation?.activityOf(route);
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
    _retiring.add(route);
    route.disable();
    remove(route);
  }
}

/// A navigation waiting for its route to reach the tree.
final class _Arrival {
  final RouteNode route;
  final Transition? transition;
  final bool replace;
  final Completer<void> settled;

  _Arrival(
    this.route, {
    required this.transition,
    required this.replace,
    required this.settled,
  });
}

sealed class _Navigation {
  final Transition transition;
  final Completer<void> settled;
  final RouteNode incoming;

  _Navigation(
    this.transition, {
    required this.settled,
    required this.incoming,
  });

  /// How far the clock has run.
  double get progress => transition.timeline.progress;

  /// Sets the clock to the end this navigation runs from.
  void start() => transition.timeline.setToStart();

  /// Moves the clock by [dt], reporting whether this navigation has landed.
  bool step(double dt) {
    final timeline = transition.timeline;
    timeline.advance(dt);
    return timeline.isFinished;
  }

  /// Poses every side at [progress].
  void pose();

  /// Returns every side to how it stands outside a navigation.
  void rest();

  /// What [route] takes part in as a side of this navigation, or null when it
  /// is not one.
  Activity? activityOf(RouteNode route);

  /// The routes on [stack] that leave it once this navigation settles.
  Iterable<RouteNode> leaving(Iterable<RouteNode> stack);
}

final class _Swap extends _Navigation {
  final RouteNode outgoing;

  _Swap(
    super.transition, {
    required super.settled,
    required super.incoming,
    required this.outgoing,
  });

  @override
  void pose() {
    transition.apply(progress, incoming, outgoing);
  }

  @override
  void rest() {
    incoming._reset();
    outgoing._reset();
  }

  @override
  Activity? activityOf(RouteNode route) {
    if (identical(route, incoming)) return transition.incoming;
    if (identical(route, outgoing)) return transition.outgoing;
    return null;
  }

  /// A swap leaves nothing behind: whichever side lost goes, and so does
  /// everything the arriving side was laid over.
  @override
  Iterable<RouteNode> leaving(Iterable<RouteNode> stack) {
    return stack.where((route) => !identical(route, incoming));
  }
}

final class _Layer extends _Navigation {
  final RouteNode covered;
  final Backdrop backdrop;

  /// Which way the clock runs. Only a push turns around, when the pop that
  /// matches it lands before it has.
  bool forward;

  _Layer(
    super.transition, {
    required super.settled,
    required super.incoming,
    required this.covered,
    required this.backdrop,
    bool? forward,
  }) : forward = forward ?? true;

  /// Turns the push around to play back, reporting whether it was still
  /// playing forward.
  bool turn() {
    if (!forward) return false;
    forward = false;
    return true;
  }

  @override
  void start() {
    if (forward) {
      transition.timeline.setToStart();
    } else {
      transition.timeline.setToEnd();
    }
  }

  @override
  bool step(double dt) {
    final timeline = transition.timeline;

    if (forward) {
      timeline.advance(dt);
      return timeline.isFinished;
    }

    timeline.recede(dt);
    return timeline.progress == 0 || timeline.duration == 0;
  }

  @override
  void pose() {
    transition.apply(progress, incoming, null);
    backdrop.apply(progress, covered);
  }

  @override
  void rest() {
    incoming._reset();
    covered._reset();
  }

  @override
  Activity? activityOf(RouteNode route) {
    if (identical(route, incoming)) return transition.incoming;
    if (identical(route, covered)) return backdrop.running & ~Activity.input;
    return null;
  }

  @override
  Iterable<RouteNode> leaving(Iterable<RouteNode> stack) => forward ? const [] : [incoming];
}
