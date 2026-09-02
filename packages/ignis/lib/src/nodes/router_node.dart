// SPDX-AI-Disclosure: ai-generated

import 'dart:async';
import 'dart:ui';

import 'package:flutter/gestures.dart' show PointerDownEvent;
import 'package:ignis/src/backdrop.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/effects/transitions/cut_transition_effect.dart';
import 'package:ignis/src/effects/nodes/transition_effect.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/inputs/nodes/hover_input.dart';
import 'package:ignis/src/nodes/input_node.dart';
import 'package:ignis/src/nodes/spatial_node.dart';

/// Route holders sit at a deep-negative floor, monotonic so a newer route
/// always paints above an older one.
const _HOLDER_FLOOR = -0x100000;

/// The transition-time chrome sits above every holder and user child, the
/// barrier just below the effect so a control bound in a transition's build
/// still wins the walk.
const _BARRIER_PRIORITY = 0x100000;
const _EFFECT_PRIORITY = 0x100000 + 1;

/// Builds a fresh [TransitionEffect] per navigation.
///
/// A default-configured transition constructor can always be used directly as
/// a tear-off, e.g. `CurtainTransitionEffect.new`.
typedef TransitionFactory = TransitionEffect Function(SpatialNode to, SpatialNode? from);

/// A stack of live routes and the operations on it. Nothing else.
///
/// Routes are ordinary nodes, built at the call site — their constructors are
/// the parameter mechanism, and there is no registry: this router does not
/// know or care what routes exist. It knows what is on the stack right now.
class RouterNode extends Node {
  /// Builds the transition a navigation plays when it names none.
  /// Null cuts straight from route to route.
  final TransitionFactory? transition;

  final Node _initial;

  RouterNode({
    required this._initial,
    this.transition,
    super.enabled,
    super.priority,
    super.children,
  });

  final List<_RouteEntry> _entries = [];
  final List<SpatialNode> _painted = [];
  final List<SpatialNode> _ticking = [];
  _Navigation? _navigation;
  int _nextHolderPriority = _HOLDER_FLOOR;

  /// The route on top. Commits at the go/push/pop call, before visuals settle.
  Node get top {
    assert(_entries.isNotEmpty, 'The router has not mounted its initial route yet.');
    return _entries.last.route;
  }

  /// Every live route, bottom to top. Never empty once mounted.
  List<Node> get stack => [for (final entry in _entries) entry.route];

  /// Whether a navigation's transition is in flight.
  bool get isTransitioning => _navigation != null;

  /// Emitted as any navigation commits. React with type patterns:
  /// `if (router.top case MenuNode()) …` — keys never existed here.
  final onStackChange = Signal0();

  @override
  void build() {
    super.build();
    provide<RouterNode>(this);

    onMount(() {
      if (_entries.isNotEmpty) return;
      _bootstrap();
    });

    onUnmount(() {
      for (var i = 0; i < _entries.length; i += 1) {
        _entries[i].complete(null);
      }
    });

    tick((dt) {
      final navigation = _navigation;

      if (navigation != null && navigation.transition.isFinished) {
        _settle();
      }

      for (var i = 0; i < _ticking.length; i += 1) {
        for (final child in _ticking[i].children) {
          child.update(dt);
        }
      }
    });
  }

  /// Replaces the whole [stack] with [route]. Every removed route's pending
  /// push future completes with null.
  void go(Node route, {TransitionFactory? transition}) {
    _forceFinish();
    final leaving = List<_RouteEntry>.of(_entries);
    _entries.clear();
    _entries.add(_spawn(route, backdrop: .frozen));

    for (var i = leaving.length - 1; i >= 0; i -= 1) {
      final holder = leaving[i].holder;
      leaving[i].complete(null);

      // Never mounted: cancel the pending add outright, zero lifecycle events.
      if (!holder.isMounted) {
        remove(holder);
        leaving.removeAt(i);
      }
    }

    _commit(
      leaving: leaving,
      from: leaving.isNotEmpty ? leaving.last.holder : null,
      covered: null,
      factory: transition,
    );
  }

  /// Lays [route] over the stack and returns the value [pop] is eventually
  /// given. [backdrop] is what this push does to the route directly beneath —
  /// frozen by default. Input beneath is blocked regardless: the stack is
  /// modal.
  ///
  /// Code after an `await` resumes later: capture `read<RouterNode>()`
  /// *before* awaiting, and re-check `isMounted` before touching your own
  /// subtree.
  Future<T?> push<T>(
    Node route, {
    Backdrop? backdrop,
    TransitionFactory? transition,
  }) {
    _forceFinish();

    assert(
      _entries.isNotEmpty,
      'Cannot push before the router has mounted its initial route.',
    );

    final completer = Completer<Object?>();
    final below = _entries.last;

    _entries.add(
      _spawn(
        route,
        backdrop: backdrop ?? .frozen,
        completer: completer,
      ),
    );

    _commit(
      leaving: [],
      from: null,
      covered: below.holder.isMounted ? below.holder : null,
      factory: transition,
    );

    return completer.future.then((result) {
      return result as T?;
    });
  }

  /// Removes the top route, waking the one beneath and completing the push
  /// that placed it with [result]. Throws a [StateError] on a stack of one.
  void pop({Object? result, TransitionFactory? transition}) {
    _forceFinish();

    if (_entries.length <= 1) {
      throw StateError('Cannot pop the last route.');
    }

    final popped = _entries.removeLast();
    popped.complete(result);
    final leaving = [popped];

    // Pushed and popped in the same frame: cancel the pending add outright.
    if (!popped.holder.isMounted) {
      remove(popped.holder);
      leaving.clear();
    }

    _commit(
      leaving: leaving,
      from: leaving.isNotEmpty ? popped.holder : null,
      covered: null,
      factory: transition,
    );
  }

  @override
  void render(Canvas canvas) {
    renderSelf(canvas);

    for (final child in children) {
      // The parent-side "a disabled child must never render" gate is
      // deliberately owned here: a painted backdrop is a disabled holder
      // that still draws.
      if (child.enabled || _isPainted(child)) {
        child.render(canvas);
      }
    }
  }

  @override
  void debugRender(Canvas canvas) {
    debugRenderSelf(canvas);

    for (final child in children) {
      if (child.enabled || _isPainted(child)) {
        child.debugRender(canvas);
      }
    }
  }

  void _bootstrap() {
    final entry = _spawn(_initial, backdrop: .frozen);
    entry.holder.enable();
    _entries.add(entry);
    _applyStates();
    _refreshPolicies();
    onStackChange.emit();
  }

  /// Wraps [route] in a holder added above every existing one.
  _RouteEntry _spawn(
    Node route, {
    required Backdrop backdrop,
    Completer<Object?>? completer,
  }) {
    final holder = SpatialNode(enabled: false, priority: _nextHolderPriority);
    _nextHolderPriority += 1;
    holder.add(route);
    add(holder);

    return _RouteEntry(
      route: route,
      holder: holder,
      backdrop: backdrop,
      completer: completer,
    );
  }

  /// Raises the chrome, spawns the transition over [from] and the new top,
  /// and flips the committed state.
  void _commit({
    required List<_RouteEntry> leaving,
    required SpatialNode? from,
    required SpatialNode? covered,
    required TransitionFactory? factory,
  }) {
    final barrier = _RouteBarrier(priority: _BARRIER_PRIORITY);
    add(barrier);

    final build = factory ?? this.transition ?? CutTransitionEffect.new;
    final transition = build(_entries.last.holder, from)..priority = _EFFECT_PRIORITY;
    add(transition);

    _navigation = _Navigation(
      leaving: leaving,
      transition: transition,
      barrier: barrier,
      painted: from ?? covered,
    );

    _applyStates();
    _refreshPolicies();
    onStackChange.emit();
  }

  /// Runs the in-flight navigation to completion, synchronously.
  void _forceFinish() {
    final navigation = _navigation;
    if (navigation == null) return;
    final transition = navigation.transition;
    transition.controller.setToEnd();
    if (transition.isMounted) transition.update(0);
    _settle();
  }

  /// Retires the chrome and the routes the last navigation left behind.
  void _settle() {
    final navigation = _navigation;
    if (navigation == null) return;
    _navigation = null;

    for (var i = 0; i < navigation.leaving.length; i += 1) {
      remove(navigation.leaving[i].holder);
    }

    remove(navigation.barrier);

    // Also cancels a pending add; a self-cleaned transition is already gone.
    final transition = navigation.transition;
    if (transition.isMounted || !transition.isFinished) remove(transition);

    _refreshPolicies();
  }

  /// The state of any non-top entry is the backdrop of the entry directly
  /// above it; the top is active.
  void _applyStates() {
    for (var i = 0; i < _entries.length; i += 1) {
      final entry = _entries[i];

      if (i == _entries.length - 1) {
        entry.presentation = .active;
        continue;
      }

      entry.presentation = switch (_entries[i + 1].backdrop) {
        .live => .live,
        .frozen => .frozen,
        .hidden => .hidden,
      };

      entry.holder.disable();
    }
  }

  /// Recomputes which disabled holders still paint, and which the router
  /// ticks itself.
  void _refreshPolicies() {
    _painted.clear();
    _ticking.clear();

    for (var i = 0; i < _entries.length; i += 1) {
      _adopt(_entries[i]);
    }

    final navigation = _navigation;
    if (navigation == null) return;

    // Routes on their way out keep their pre-commit policy until settle.
    for (var i = 0; i < navigation.leaving.length; i += 1) {
      _adopt(navigation.leaving[i]);
    }

    // The route the navigation leaves or covers keeps painting until settle,
    // even when its new state is hidden.
    final painted = navigation.painted;

    if (painted != null && !painted.enabled && !_painted.contains(painted)) {
      _painted.add(painted);
    }
  }

  void _adopt(_RouteEntry entry) {
    switch (entry.presentation) {
      case .live:
        _painted.add(entry.holder);
        _ticking.add(entry.holder);

      case .frozen:
        _painted.add(entry.holder);

      case .active:
      case .hidden:
    }
  }

  bool _isPainted(Node child) {
    for (var i = 0; i < _painted.length; i += 1) {
      if (identical(_painted[i], child)) return true;
    }

    return false;
  }
}

/// How a stack entry presents while it is not being driven by its own
/// enabled flag.
enum _Presentation {
  active,
  live,
  frozen,
  hidden,
}

final class _RouteEntry {
  final Node route;
  final SpatialNode holder;

  /// What this entry's push does to the entry directly beneath it.
  final Backdrop backdrop;

  /// Completes the push future; null for go-placed and initial routes.
  final Completer<Object?>? completer;

  _Presentation presentation = .active;

  _RouteEntry({
    required this.route,
    required this.holder,
    required this.backdrop,
    this.completer,
  });

  void complete(Object? result) {
    final completer = this.completer;
    if (completer == null || completer.isCompleted) return;
    completer.complete(result);
  }
}

/// One in-flight navigation: the routes on their way out and the chrome
/// playing them out.
final class _Navigation {
  final List<_RouteEntry> leaving;
  final TransitionEffect transition;
  final _RouteBarrier barrier;

  /// The holder this navigation leaves or covers, kept painting until settle.
  final SpatialNode? painted;

  _Navigation({
    required this.leaving,
    required this.transition,
    required this.barrier,
    required this.painted,
  });
}

/// The transition-time input barrier: a full-scene opaque hit area that
/// claims hovers and pointer downs, plus a node-bound catch-all key bind.
final class _RouteBarrier extends HoverInput {
  _RouteBarrier({super.priority});

  @override
  void build() {
    super.build();

    onSceneResize((size) {
      shape = .rectangle(size);
    });

    Ignis.controls.bind(
      _mute,
      matchers: const {_AnyControlEvent()},
    );
  }

  @override
  InputResult register(PointerDownEvent event, _) => .handled;

  /// Claims the event so nothing beneath the barrier hears it.
  void _mute(ControlEvent event) {}
}

/// Accepts every control event, which is what makes the barrier's bind a
/// catch-all.
final class _AnyControlEvent implements ControlEvent {
  const _AnyControlEvent();

  @override
  bool accepts(ControlEvent emitted) => true;
}
