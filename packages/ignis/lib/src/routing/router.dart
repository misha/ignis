// SPDX-AI-Disclosure: ai-generated

import 'dart:async';

import 'package:ignis/src/core.dart';
import 'package:ignis/src/routing/backdrop.dart';
import 'package:ignis/src/routing/nodes/route_node.dart';
import 'package:ignis/src/routing/transition.dart';
import 'package:ignis/src/routing/transitions/cut_transition.dart';

/// A stack of [RouteNode]s managed with a set of classic routing operations.
///
/// A router isn't a node itself. A `RouterNode` generally drives it with the
/// clock from an actual scene.
class Router<T> {
  /// The transition a navigation plays when it names none.
  ///
  /// Defaults to a [CutTransition].
  final Transition transition;

  /// Emitted when a navigation begins.
  final onStart = Signal1<Transition>();

  /// Emitted when a navigation settles.
  final onSettle = Signal1<Transition>();

  final List<RouteNode<T>> _routes = [];
  final List<_Entry<T>> _stack = [];
  T? _initial;
  _Navigation<T>? _navigation;

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

  /// Whether a navigation is running.
  bool get isTransitioning => _navigation != null;

  /// The running navigation's progress, or 1 between navigations.
  double get progress => _navigation?.transition.timeline.progress ?? 1;

  /// Moves the running navigation by [dt] seconds.
  void process(double dt) {
    final navigation = _navigation;
    if (navigation == null) return;
    final timeline = navigation.transition.timeline;

    if (navigation.forward) {
      timeline.advance(dt);

      if (timeline.isFinished) {
        _settle();
        return;
      }
    } else {
      timeline.recede(dt);

      if (timeline.progress == 0 || timeline.duration == 0) {
        _settle();
        return;
      }
    }

    _pose(navigation);
  }

  /// Replaces the whole stack with the route named [name], playing
  /// [transition] over the default. While a navigation runs, naming the route
  /// being left reverses it, naming the current target keeps it running
  /// forward, and naming a third route completes it first.
  /// Every push dropped completes with null.
  void go(
    T name, {
    Transition? transition,
  }) {
    final target = _route(name);
    assert(target != null, 'No route is named "$name".');
    final navigation = _navigation;

    if (navigation != null) {
      if (name == top) {
        navigation.forward = true;
        return;
      }

      if (identical(target, navigation.outgoing)) {
        _entries
          ..clear()
          ..add(_Entry(target!));
        navigation.forward = false;
        return;
      }

      _settle();
    }

    if (name == top) {
      _collapse();
      return;
    }

    _swap(target!, transition);
  }

  /// Lays the route named [name] over the top, playing [transition] over the
  /// default and leaving the covered route to [backdrop], frozen by default.
  /// Completes with what the matching [pop] carries, or null when a [go]
  /// drops the push.
  Future<R?> push<R>(
    T name, {
    Transition? transition,
    Backdrop? backdrop,
  }) {
    final target = _route(name);
    assert(target != null, 'No route is named "$name".');

    assert(
      !_entries.any((entry) => identical(entry.route, target)),
      'Route "$name" is already on the stack.',
    );

    if (_navigation != null) _settle();
    final covered = _entries.last.route;
    final completer = Completer<R?>();

    final entry = _Entry(
      target!,
      backdrop: backdrop ?? const .frozen(),
      transition: transition,
      completer: completer,
    );

    _entries.add(entry);
    _order();

    _launch(
      _Navigation(
        entry.transition ?? this.transition,
        incoming: target,
        covered: covered,
        backdrop: entry.backdrop,
      ),
    );

    return completer.future;
  }

  /// Plays the top route's push back, uncovering the route beneath and
  /// completing the push with [result], which must be of the type it asked
  /// for. Throws a [StateError] on a stack of one.
  void pop([Object? result]) {
    if (_entries.length <= 1) throw StateError('Cannot pop the last route.');
    final entry = _entries.removeLast();
    _order();
    final navigation = _navigation;

    if (navigation != null &&
        identical(navigation.incoming, entry.route) &&
        navigation.outgoing == null) {
      navigation.forward = false;
    } else {
      if (navigation != null) _settle();

      _launch(
        _Navigation(
          entry.transition ?? transition,
          incoming: entry.route,
          covered: _entries.last.route,
          backdrop: entry.backdrop,
          forward: false,
        ),
      );
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
    route.activity = _activityOf(route);
  }

  /// Removes [route], settling any navigation it is a side of.
  void remove(RouteNode<T> route) {
    _routes.remove(route);
    _stack.removeWhere((entry) => identical(entry.route, route));
    final navigation = _navigation;
    if (navigation == null) return;

    if (identical(route, navigation.incoming) ||
        identical(route, navigation.outgoing) ||
        identical(route, navigation.covered)) {
      _settle();
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
      entry.completer?.complete(null);
    }

    entries
      ..clear()
      ..add(_Entry(top.route));

    _order();
    _arrange();
  }

  void _swap(RouteNode<T> incoming, Transition? transition) {
    _collapse();
    final outgoing = _entries.last.route;
    _entries
      ..clear()
      ..add(_Entry(incoming));

    _order();
    outgoing.priority = -1;

    _launch(
      _Navigation(
        transition ?? this.transition,
        incoming: incoming,
        outgoing: outgoing,
      ),
    );
  }

  /// Orders the stack's routes bottom to top.
  void _order() {
    for (final (index, entry) in _entries.indexed) {
      entry.route.priority = index;
    }
  }

  /// What [route] takes part in right now: a side of the running navigation is
  /// live, a covered one is in its backdrop's running state, the top is live, a stacked
  /// one is in the settled state of the backdrop above it, and the rest take
  /// no part.
  Activity _activityOf(RouteNode<T> route) {
    final navigation = _navigation;

    if (navigation != null) {
      if (identical(route, navigation.incoming) || identical(route, navigation.outgoing)) {
        return .all;
      }

      if (identical(route, navigation.covered)) {
        return navigation.backdrop!.running & ~Activity.input;
      }
    }

    if (_stack.isEmpty) {
      return route.name == _initial ? .all : .none;
    }

    for (final (index, entry) in _stack.indexed) {
      if (!identical(entry.route, route)) continue;
      if (index == _stack.length - 1) return .all;
      return _stack[index + 1].backdrop!.settled & ~Activity.input;
    }

    return .none;
  }

  /// Gives every route what it takes part in.
  void _arrange() {
    for (final route in _routes) {
      route.activity = _activityOf(route);
    }
  }

  /// Poses every side of [navigation] at its progress.
  void _pose(_Navigation<T> navigation) {
    final progress = navigation.transition.timeline.progress;
    navigation.transition.apply(progress, navigation.incoming, navigation.outgoing);
    final covered = navigation.covered;
    if (covered != null) navigation.backdrop!.apply(progress, covered);
  }

  /// Starts [navigation]: its clock at the end it runs from, every side arranged
  /// and posed, its chrome above the stack, and the navigation announced.
  void _launch(_Navigation<T> navigation) {
    _navigation = navigation;
    final transition = navigation.transition;
    final timeline = transition.timeline;

    if (navigation.forward) {
      timeline.setToStart();
    } else {
      timeline.setToEnd();
    }

    _arrange();
    _pose(navigation);
    final chrome = transition.chrome;

    if (chrome != null) {
      chrome.priority = _entries.length + 1;
      chrome.enable();
    }

    onStart.emit(transition);
  }

  /// Ends the navigation, returning every side to rest.
  void _settle() {
    final navigation = _navigation;
    if (navigation == null) return;
    _navigation = null;
    navigation.incoming.reset();
    navigation.outgoing?.reset();
    navigation.covered?.reset();
    _arrange();
    final transition = navigation.transition;
    transition.chrome?.disable();
    onSettle.emit(transition);
  }
}

final class _Entry<T> {
  final RouteNode<T> route;
  final Backdrop? backdrop;
  final Transition? transition;
  final Completer<Object?>? completer;

  _Entry(
    this.route, {
    this.backdrop,
    this.transition,
    this.completer,
  });
}

final class _Navigation<T> {
  final Transition transition;
  final RouteNode<T> incoming;
  final RouteNode<T>? outgoing;
  final RouteNode<T>? covered;
  final Backdrop? backdrop;
  bool forward;

  _Navigation(
    this.transition, {
    required this.incoming,
    this.outgoing,
    this.covered,
    this.backdrop,
    bool? forward,
  }) : forward = forward ?? true;
}
