// SPDX-AI-Disclosure: ai-generated

import 'dart:async';

import 'package:ignis/src/core.dart';
import 'package:ignis/src/routing/nodes/route_node.dart';
import 'package:ignis/src/routing/transition.dart';
import 'package:ignis/src/routing/transitions/cut_transition.dart';

/// A stack of [RouteNode]s and the navigations over it, playing a
/// [Transition] per navigation. It owns the routes' activity, priority, and
/// pose. A transition may be reused: each navigation restarts its clock.
///
/// Plain state that never enters the tree. A `RouterNode` adds its routes,
/// drives [process], mounts the chrome of the transition [onStart] emits and
/// removes the one [onSettle] emits, and provides this router to everything
/// beneath it.
///
/// [go] replaces the whole stack with one route, so a router that only ever
/// goes is a switcher: one route takes part and the rest take no part at all.
/// [push] lays a route over the top and leaves the covered one to whatever
/// [Activity] the push allows it, painting at least and never hearing input.
/// [pop] plays the push back. Mid-flight both sides are live, the lower one
/// painting below the upper one and the chrome above all, and their pose is a
/// pure function of the transition's progress, so a navigation can be reversed
/// at any moment: [go] with the name being left reverses, with the current
/// target runs forward, and with a third name completes the running navigation
/// first. Every navigation commits at the call: [top] and [stack] answer for
/// it at once, before the visuals settle.
class Router<T> {
  /// The transition a navigation plays when it names none. Defaults to a
  /// [CutTransition].
  final Transition transition;

  /// Emits the transition a navigation starts, its chrome enabled and
  /// prioritized above the routes, ready to mount.
  final onStart = Signal1<Transition>();

  /// Emits the transition a navigation settles, its chrome disabled, ready to
  /// remove.
  final onSettle = Signal1<Transition>();

  final List<RouteNode<T>> _routes = [];
  final List<_Entry<T>> _stack = [];
  T? _initial;
  Transition? _transition;
  bool _forward = true;
  RouteNode<T>? _incoming;
  RouteNode<T>? _outgoing;

  Router({
    T? top,
    Transition? transition,
  }) : _initial = top,
       transition = transition ?? CutTransition();

  /// The stack, materialized on the first route once anything asks for it.
  List<_Entry<T>> get _entries {
    if (_stack.isEmpty) {
      assert(_routes.isNotEmpty, 'No route has been added yet.');
      final name = _initial ??= _routes.first.name;
      final bottom = _route(name);
      assert(bottom != null, 'No route is named "$name".');
      _stack.add(_Entry(bottom!));
    }

    return _stack;
  }

  /// The name of the route on top: the one the constructor named, else the
  /// first route added, until a navigation names another.
  T get top => _entries.last.route.name;

  /// The names on the stack, bottom to top.
  List<T> get stack => [
    for (final entry in _entries) //
      entry.route.name,
  ];

  /// Whether a navigation's transition is in flight.
  bool get isTransitioning => _transition != null;

  /// The in-flight navigation's progress, or 1 between navigations.
  double get progress => _transition?.timeline.progress ?? 1;

  /// Moves the navigation in flight by [dt] seconds.
  void process(double dt) {
    final flight = _transition;
    if (flight == null) return;
    final timeline = flight.timeline;

    if (_forward) {
      timeline.advance(dt);

      if (timeline.isFinished) {
        _settle(forward: true);
        return;
      }
    } else {
      timeline.recede(dt);

      if (timeline.progress == 0 || timeline.duration == 0) {
        _settle(forward: false);
        return;
      }
    }

    flight.apply(timeline.progress, _incoming!, _outgoing);
  }

  /// Replaces the whole stack with the route named [name], playing
  /// [transition] over the default. Mid-flight, naming the route being left
  /// reverses the navigation, naming the current target keeps it running
  /// forward, and naming a third route completes the running navigation first.
  /// Every push dropped completes with null.
  void go(
    T name, {
    Transition? transition,
  }) {
    final target = _route(name);
    assert(target != null, 'No route is named "$name".');

    if (_transition != null) {
      if (name == top) {
        _forward = true;
        return;
      }

      if (identical(target, _outgoing)) {
        _entries
          ..clear()
          ..add(_Entry(target!));
        _forward = false;
        return;
      }

      _settle(forward: _forward);
    }

    if (name == top) {
      _collapse();
      return;
    }

    _swap(target!, transition);
  }

  /// Lays the route named [name] over the top, playing [transition] over the
  /// default. The covered route takes part in [backdrop] once the push settles,
  /// painting throughout and never hearing input; by default it only paints,
  /// frozen in place. Completes with what the matching [pop] carries, or null
  /// when a [go] drops the push.
  Future<R?> push<R>(
    T name, {
    Transition? transition,
    Activity? backdrop,
  }) {
    final target = _route(name);
    assert(target != null, 'No route is named "$name".');

    assert(
      !_entries.any((entry) => identical(entry.route, target)),
      'Route "$name" is already on the stack.',
    );

    if (_transition != null) _settle(forward: _forward);
    final covered = _entries.last.route;
    final allowed = (backdrop ?? .render) & ~Activity.input;
    covered.activity = allowed | .render;
    target!.activity = .all;
    final flight = transition ?? this.transition;
    final completer = Completer<R?>();

    _entries.add(
      _Entry(
        target,
        backdrop: allowed,
        transition: flight,
        completer: completer,
      ),
    );

    _order();
    _incoming = target;
    _outgoing = null;
    _forward = true;
    _transition = flight;
    flight.timeline.setToStart();
    flight.apply(flight.timeline.progress, target, null);
    _start(flight);
    return completer.future;
  }

  /// Plays the top route's push back, uncovering the route beneath and
  /// completing the push with [result], which must be of the type it asked
  /// for. Throws a [StateError] on a stack of one.
  void pop([Object? result]) {
    if (_entries.length <= 1) throw StateError('Cannot pop the last route.');
    final entry = _entries.removeLast();
    _order();
    _entries.last.route.activity = entry.backdrop | .render;

    if (_transition != null && identical(_incoming, entry.route) && _outgoing == null) {
      _forward = false;
    } else {
      if (_transition != null) _settle(forward: _forward);
      final flight = entry.transition ?? transition;
      _incoming = entry.route;
      _outgoing = null;
      _forward = false;
      _transition = flight;
      flight.timeline.setToEnd();
      flight.apply(flight.timeline.progress, entry.route, null);
      _start(flight);
    }

    entry.completer?.complete(result);
  }

  /// Adds [route] to those a navigation can name. Off the stack, it takes no
  /// part. Asserts that no route shares its name.
  void add(RouteNode<T> route) {
    assert(
      !_routes.any((other) => other.name == route.name),
      'A route is already named "${route.name}".',
    );

    _routes.add(route);
    _initial ??= route.name;
    if (identical(route, _incoming) || identical(route, _outgoing)) return;

    final stacked = _stack.isEmpty
        ? route.name == _initial
        : _stack.any((entry) => identical(entry.route, route));

    if (stacked) return;
    route.activity = .none;
  }

  /// Removes [route], settling any navigation it is a side of.
  void remove(RouteNode<T> route) {
    _routes.remove(route);
    _stack.removeWhere((entry) => identical(entry.route, route));

    if (identical(route, _incoming) || identical(route, _outgoing)) {
      _settle(forward: identical(route, _outgoing));
    }
  }

  RouteNode<T>? _route(T name) {
    for (final route in _routes) {
      if (route.name == name) return route;
    }

    return null;
  }

  /// Drops every entry beneath the top, which takes no part from here on, and
  /// completes every push on the stack with null.
  void _collapse() {
    final entries = _entries;
    final top = entries.last;

    for (final entry in entries) {
      if (!identical(entry, top)) entry.route.activity = .none;
      entry.completer?.complete(null);
    }

    entries
      ..clear()
      ..add(_Entry(top.route));

    _order();
  }

  void _swap(RouteNode<T> incoming, Transition? transition) {
    _collapse();
    final outgoing = _entries.last.route;
    _entries
      ..clear()
      ..add(_Entry(incoming));

    _order();
    outgoing.priority = -1;
    incoming.activity = .all;
    _outgoing = outgoing;
    _incoming = incoming;
    _forward = true;

    final flight = transition ?? this.transition;
    _transition = flight;
    flight.timeline.setToStart();
    flight.apply(flight.timeline.progress, incoming, outgoing);
    _start(flight);
  }

  /// Orders the stack's routes bottom to top.
  void _order() {
    for (final (index, entry) in _entries.indexed) {
      entry.route.priority = index;
    }
  }

  /// Readies [flight]'s chrome above the stack and announces the navigation.
  void _start(Transition flight) {
    final chrome = flight.chrome;

    if (chrome != null) {
      chrome.priority = _entries.length + 1;
      chrome.enable();
    }

    onStart.emit(flight);
  }

  /// Ends the flight: a swap retires its loser, a push settles the covered
  /// route into what it was allowed, a pop retires the popped route and wakes
  /// the one beneath.
  void _settle({
    required bool forward,
  }) {
    final flight = _transition;
    if (flight == null) return;
    final incoming = _incoming!;
    final outgoing = _outgoing;
    _transition = null;
    _incoming = null;
    _outgoing = null;
    incoming.reset();
    outgoing?.reset();

    if (outgoing != null) {
      (forward ? outgoing : incoming).activity = .none;
    } else if (forward) {
      final entries = _entries;

      if (entries.length > 1) {
        entries[entries.length - 2].route.activity = entries.last.backdrop;
      }
    } else {
      incoming.activity = .none;
      _entries.last.route.activity = .all;
    }

    flight.chrome?.disable();
    onSettle.emit(flight);
  }
}

final class _Entry<T> {
  final RouteNode<T> route;
  final Activity backdrop;
  final Transition? transition;
  final Completer<Object?>? completer;

  _Entry(
    this.route, {
    this.backdrop = .none,
    this.transition,
    this.completer,
  });
}
