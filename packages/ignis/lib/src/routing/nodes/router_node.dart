// SPDX-AI-Disclosure: ai-generated

import 'dart:async';

import 'package:ignis/src/core.dart';
import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/routing/backdrop.dart';
import 'package:ignis/src/routing/nodes/route_node.dart';
import 'package:ignis/src/routing/transition.dart';
import 'package:ignis/src/routing/transitions/cut_transition.dart';

/// A stack of [RouteNode]s, managed with a set of classic routing operations.
///
/// Its [RouteNode] children are the stack, bottom to top: [push] lays one over
/// the rest, [pop] takes the top away, and [go] replaces the lot. Nothing is
/// held aside, so a route that leaves the stack leaves the tree, and one
/// returned to is built again.
///
/// A navigation asked for while another runs settles the running one first.
/// [push] and [go] start on the tick after the call, since the route they add
/// only reaches the tree at the next flush.
///
/// The region routed is the [shape] in effect above this node, or the scene's
/// when nothing spatial is above, as a layout root takes it. The routes and
/// the chrome fill that region.
class RouterNode extends SpatialNode {
  /// The transition a navigation plays when it names none.
  ///
  /// Defaults to a [CutTransition].
  final Transition transition;

  /// Emitted when a navigation begins.
  final onStart = Signal1<Transition>();

  /// Emitted when a navigation settles.
  final onSettle = Signal1<Transition>();

  /// The stack, bottom to top.
  late final Iterable<RouteNode> _children = query<RouteNode>();

  /// The stack, bottom to top.
  ///
  /// A route taken off the stack is still a child until the next flush, so
  /// what is leaving is filtered out rather than waited on.
  Iterable<RouteNode> get routes {
    if (_retiring.isEmpty) return _children;
    return _children.where((route) => !_retiring.contains(route));
  }

  final Set<RouteNode> _retiring = .identity();
  _Navigation? _navigation;
  _Arrival? _arrival;

  RouterNode({
    Transition? transition,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : transition = transition ?? CutTransition(),
       super(inherit: .scene);

  /// The route on top, or null while the stack is empty.
  RouteNode? get top => routes.isEmpty ? null : routes.last;

  /// The priority that sits above every route on the stack.
  ///
  /// Both an arriving route and a navigation's chrome are placed with this,
  /// so the two never disagree about what "on top" means.
  int get _above => (top?.priority ?? -1) + 1;

  /// Whether a navigation is running.
  bool get isTransitioning => _navigation != null;

  /// The running navigation's progress, or 1 between navigations.
  double get progress => _navigation?.transition.timeline.progress ?? 1;

  @override
  void build() {
    super.build();
    _arrange();
    tick(_process);
  }

  /// Replaces the whole stack with [route], playing [transition] over the
  /// default, and completes once the navigation settles.
  ///
  /// A navigation already running is settled first. Every push dropped
  /// completes with null.
  Future<void> go(RouteNode route, {Transition? transition}) {
    return _arrive(route, transition, replacing: true);
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
    route.completer = completer;
    _arrive(route, null, replacing: false);
    return completer.future;
  }

  /// Plays the top route's push back, uncovering the route beneath and
  /// completing the push with [result], which must be of the type it asked
  /// for. Completes once the navigation settles. Throws a [StateError] on a
  /// stack of one.
  Future<void> pop([Object? result]) {
    final stack = routes;
    if (stack.length <= 1) throw StateError('Cannot pop the last route.');
    final leaving = stack.last;

    // Popping the push still in flight plays it back rather than settling it.
    if (_navigation case final _Layer layer when identical(layer.incoming, leaving)) {
      layer.forward = false;
      leaving.completer?.complete(result);
      leaving.completer = null;
      return layer.settled.future;
    }

    if (_navigation != null) _settle();

    final navigation = _Layer(
      leaving.transition ?? transition,
      settled: Completer<void>(),
      incoming: leaving,
      covered: stack.elementAt(stack.length - 2),
      backdrop: leaving.backdrop,
      forward: false,
    );

    _launch(navigation);
    leaving.completer?.complete(result);
    leaving.completer = null;
    return navigation.settled.future;
  }

  /// Adds [route] and records it as the navigation to start once the tree has
  /// taken it, dropping whatever was arriving before it.
  Future<void> _arrive(
    RouteNode route,
    Transition? transition, {
    required bool replacing,
  }) {
    _drop();
    if (_navigation != null) _settle();

    // Checked after settling, since that is what takes the departing route
    // off the stack and so makes room to go back to it.
    assert(!routes.contains(route), 'That route is already on the stack.');

    final arrival = _Arrival(
      route,
      transition: transition,
      replacing: replacing,
      settled: Completer<void>(),
    );

    _arrival = arrival;
    route.priority = _above;
    add(route);
    return arrival.settled.future;
  }

  /// Abandons the arriving route, which never made it onto the stack.
  void _drop() {
    final arrival = _arrival;
    if (arrival == null) return;
    _arrival = null;
    arrival.route.completer?.complete(null);
    arrival.route.completer = null;
    remove(arrival.route);
    arrival.settled.complete();
  }

  /// Starts the arrival now that its route stands in the tree.
  void _begin(_Arrival arrival) {
    final route = arrival.route;
    final stack = routes;
    final covered = stack.length > 1 ? stack.elementAt(stack.length - 2) : null;

    // Nothing to cover or leave, so the route simply stands.
    if (covered == null) {
      _arrange();
      arrival.settled.complete();
      return;
    }

    if (!arrival.replacing) {
      _launch(
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

    _launch(
      _Swap(
        arrival.transition ?? route.transition ?? transition,
        settled: arrival.settled,
        incoming: route,
        outgoing: covered,
      ),
    );
  }

  void _process(double dt) {
    // Whatever left last tick has flushed out of the tree by now.
    _retiring.clear();
    _arrange();
    final arrival = _arrival;

    if (arrival != null && arrival.route.isMounted) {
      _arrival = null;
      _begin(arrival);
      return;
    }

    final navigation = _navigation;
    if (navigation == null) return;

    if (navigation.step(dt)) {
      _settle();
      return;
    }

    _pose(navigation);
  }

  /// What [route] takes part in right now, given the [covering] route above
  /// it or null when it is the top: a side of the running navigation takes
  /// what its transition names for that side, a covered one is in its
  /// backdrop's running state, the top is live, and one beneath is in the
  /// settled state of the backdrop above it.
  Activity _activityOf(RouteNode route, RouteNode? covering) {
    final navigation = _navigation;

    if (navigation != null) {
      if (identical(route, navigation.incoming)) return navigation.transition.incoming;

      switch (navigation) {
        case _Swap(:final outgoing):
          if (identical(route, outgoing)) return navigation.transition.outgoing;

        case _Layer(:final covered, :final backdrop):
          if (identical(route, covered)) return backdrop.running & ~Activity.input;
      }
    }

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

  /// Poses every side of [navigation] at its progress.
  void _pose(_Navigation navigation) {
    final progress = navigation.transition.timeline.progress;

    switch (navigation) {
      case _Swap(:final outgoing):
        navigation.transition.apply(progress, navigation.incoming, outgoing);

      case _Layer(:final covered, :final backdrop):
        navigation.transition.apply(progress, navigation.incoming, null);
        backdrop.apply(progress, covered);
    }
  }

  /// Starts [navigation]: its clock at the end it runs from, every route
  /// arranged and posed, its chrome above the stack, and the start announced.
  void _launch(_Navigation navigation) {
    _navigation = navigation;
    final transition = navigation.transition;

    if (navigation.forward) {
      transition.timeline.setToStart();
    } else {
      transition.timeline.setToEnd();
    }

    _arrange();
    _pose(navigation);
    final chrome = transition.chrome;

    if (chrome != null) {
      chrome.priority = _above;
      add(chrome);
    }

    onStart.emit(transition);
  }

  /// Ends the navigation, taking whichever routes it left off the stack.
  ///
  /// The clock has already landed by the time this runs, so posing once more
  /// is what finishes the transition: the tick that lands it settles instead
  /// of posing, and nothing else returns the chrome to rest.
  void _settle() {
    final navigation = _navigation;
    if (navigation == null) return;
    _navigation = null;
    _pose(navigation);
    navigation.incoming.reset();

    switch (navigation) {
      // A swap leaves nothing behind: whichever side lost goes, and so does
      // everything the arriving side was laid over.
      case _Swap():
        navigation.outgoing.reset();

        for (final other in routes.toList(growable: false)) {
          if (identical(other, navigation.incoming)) continue;
          _retire(other);
        }

      case _Layer(:final covered):
        covered.reset();
        if (!navigation.forward) _retire(navigation.incoming);
    }

    _order();
    _arrange();
    final transition = navigation.transition;
    final chrome = transition.chrome;
    if (chrome != null) remove(chrome);
    onSettle.emit(transition);
    navigation.settled.complete();
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
    route.completer?.complete(null);
    route.completer = null;
    _retiring.add(route);
    route.disable();
    remove(route);
  }
}

/// A navigation waiting for its route to reach the tree.
final class _Arrival {
  final RouteNode route;
  final Transition? transition;
  final bool replacing;
  final Completer<void> settled;

  _Arrival(
    this.route, {
    required this.transition,
    required this.replacing,
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

  /// Which way the clock runs. Only a push turns around, when the pop that
  /// matches it lands before it has.
  bool get forward => true;

  /// Moves the clock by [dt], reporting whether the navigation has landed.
  bool step(double dt) {
    final timeline = transition.timeline;

    if (forward) {
      timeline.advance(dt);
      return timeline.isFinished;
    } else {
      timeline.recede(dt);
      return timeline.progress == 0 || timeline.duration == 0;
    }
  }
}

final class _Swap extends _Navigation {
  final RouteNode outgoing;

  _Swap(
    super.transition, {
    required super.settled,
    required super.incoming,
    required this.outgoing,
  });
}

final class _Layer extends _Navigation {
  final RouteNode covered;
  final Backdrop backdrop;

  @override
  bool forward;

  _Layer(
    super.transition, {
    required super.settled,
    required super.incoming,
    required this.covered,
    required this.backdrop,
    bool? forward,
  }) : forward = forward ?? true;
}
