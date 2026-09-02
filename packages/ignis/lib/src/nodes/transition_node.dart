// SPDX-AI-Disclosure: ai-generated

import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/nodes/transition_group_node.dart';
import 'package:ignis/src/transition.dart';
import 'package:ignis/src/transitions/cut_transition.dart';

/// Builds a fresh [Transition] per swap. A default-configured constructor can
/// always be used directly as a tear-off, e.g. `CurtainTransition.new`.
typedef TransitionFactory = Transition Function();

/// A permanent layer that swaps between the [TransitionGroupNode]s registered
/// beneath it, playing a [Transition] per swap.
///
/// Exactly one group shows at a time; the rest are disabled, so they neither
/// tick, hit-test, nor hear their binds. Anything beneath this node that is
/// not inside a group is unaffected by swapping. Mid-swap both sides are live
/// and their pose is a pure function of the transition's progress, so a swap
/// can be reversed at any moment: [show] with the name being left reverses,
/// with the current target runs forward, and with a third name completes the
/// running swap and starts fresh.
class TransitionNode<T> extends Node {
  /// Builds the transition a swap plays when [show] names none.
  /// Null cuts straight from group to group.
  final TransitionFactory? transition;

  final Map<T, TransitionGroupNode<T>> _groups = {};
  T? _shown;
  (T, TransitionFactory?)? _pending;
  Transition? _transition;
  bool _forward = true;
  TransitionGroupNode<T>? _incoming;
  TransitionGroupNode<T>? _outgoing;

  TransitionNode({
    this._shown,
    this.transition,
    super.enabled,
    super.priority,
    super.children,
  });

  /// The name of the showing group. Commits at the [show] call, before the
  /// visuals settle.
  T get shown {
    if (_pending case (final name, _)) return name;
    assert(_shown != null, 'No group has registered yet.');
    return _shown as T;
  }

  /// Whether a swap's transition is in flight.
  bool get isTransitioning => _transition != null;

  @override
  void build() {
    super.build();

    tick((dt) {
      final flight = _transition;
      if (flight == null) return;
      final controller = flight.controller;

      if (_forward) {
        controller.advance(dt);

        if (controller.isFinished) {
          _settle(loser: _outgoing!);
          return;
        }
      } else {
        controller.recede(dt);

        if (controller.progress == 0 || controller.duration == 0) {
          _settle(loser: _incoming!);
          return;
        }
      }

      flight.apply(controller.progress, scene.size, incoming: _incoming!, outgoing: _outgoing!);
    });
  }

  /// Swaps to the group registered under [name], playing [transition] over
  /// the default. Mid-flight, naming the group being left reverses the swap,
  /// naming the current target keeps it running forward, and naming a third
  /// group completes the running swap first.
  ///
  /// Callable before mounting: the swap begins once its groups register.
  void show(T name, {TransitionFactory? transition}) {
    if (!isMounted) {
      _pending = (name, transition);
      return;
    }

    assert(_groups.containsKey(name), 'No group is registered under "$name".');

    if (_transition != null) {
      if (name == _shown) {
        _forward = true;
        return;
      }

      if (identical(_groups[name], _outgoing)) {
        _shown = name;
        _forward = false;
        return;
      }

      _settle(loser: (_forward ? _outgoing : _incoming)!);
    }

    if (name == _shown) return;
    _swap(name, transition);
  }

  void _swap(T name, TransitionFactory? transition) {
    final outgoing = _groups[_shown]!;
    final incoming = _groups[name]!;
    incoming.enable();
    _outgoing = outgoing;
    _incoming = incoming;
    _shown = name;
    _forward = true;

    final flight = (transition ?? this.transition ?? CutTransition.new)();
    _transition = flight;
    flight.apply(flight.controller.progress, scene.size, incoming: incoming, outgoing: outgoing);
  }

  @override
  void render(Canvas canvas) {
    super.render(canvas);
    final flight = _transition;
    if (flight != null) flight.paintChrome(canvas, flight.controller.progress, scene.size);
  }

  @internal
  void register(TransitionGroupNode<T> group) {
    assert(
      !_groups.containsKey(group.name),
      'A group is already registered under "${group.name}".',
    );

    _groups[group.name] = group;
    _shown ??= group.name;

    if (group.name == _shown) {
      group.enable();
    } else {
      group.disable();
    }

    _startPending();
  }

  /// Starts a swap shown before mounting, once its groups have registered.
  void _startPending() {
    final pending = _pending;
    if (pending == null) return;
    final (name, transition) = pending;
    if (!_groups.containsKey(name)) return;
    _pending = null;
    if (name == _shown) return;
    _swap(name, transition);
  }

  @internal
  void unregister(TransitionGroupNode<T> group) {
    _groups.remove(group.name);

    if (identical(group, _incoming) || identical(group, _outgoing)) {
      _settle(loser: group);
    }
  }

  void _settle({required TransitionGroupNode<T> loser}) {
    if (_transition == null) return;
    final incoming = _incoming!;
    final outgoing = _outgoing!;
    _transition = null;
    _incoming = null;
    _outgoing = null;
    incoming.reset();
    outgoing.reset();
    loser.disable();
  }
}
