// SPDX-AI-Disclosure: ai-generated

import 'package:flutter/foundation.dart';
import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/nodes/transition_group_node.dart';
import 'package:ignis/src/transition.dart';
import 'package:ignis/src/transitions/cut_transition.dart';

/// A permanent layer that swaps between its [TransitionGroupNode] children,
/// playing a [Transition] per swap. It owns their enablement, priority, and
/// pose. A transition may be reused: each swap restarts its clock and
/// re-mounts its chrome.
///
/// The region swapped is the [shape] in effect above this node, or the scene's
/// when nothing spatial is above, as a layout root takes it. The groups and
/// the transition's chrome fill that region.
///
/// Exactly one group shows at a time; the rest are disabled, so they neither
/// tick, hit-test, nor hear their binds. Mid-swap both sides are live, the
/// outgoing one painting below the incoming one and the chrome above both,
/// and their pose is a pure function of the transition's progress, so a swap
/// can be reversed at any moment: [show] with the name being left reverses,
/// with the current target runs forward, and with a third name completes the
/// running swap and starts fresh.
class TransitionNode<T> extends SpatialNode {
  /// The transition a swap plays when [show] names none. Defaults to a
  /// [CutTransition].
  final Transition transition;

  T? _shown;
  Transition? _transition;
  bool _forward = true;
  TransitionGroupNode<T>? _incoming;
  TransitionGroupNode<T>? _outgoing;

  TransitionNode({
    this._shown,
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

  Iterable<TransitionGroupNode<T>> get _groups => query<TransitionGroupNode<T>>();

  /// The name of the showing group, the first child's until [show] names
  /// another. Commits at the [show] call, before the visuals settle.
  T get shown {
    assert(_groups.isNotEmpty, 'No group has been added yet.');
    return _shown ??= _groups.first.name;
  }

  /// Whether a swap's transition is in flight.
  bool get isTransitioning => _transition != null;

  /// The in-flight swap's progress, or 1 between swaps.
  double get progress => _transition?.timeline.progress ?? 1;

  @override
  void build() {
    super.build();

    tick((dt) {
      final flight = _transition;
      if (flight == null) return;
      final timeline = flight.timeline;

      if (_forward) {
        timeline.advance(dt);

        if (timeline.isFinished) {
          _settle(loser: _outgoing!);
          return;
        }
      } else {
        timeline.recede(dt);

        if (timeline.progress == 0 || timeline.duration == 0) {
          _settle(loser: _incoming!);
          return;
        }
      }

      flight.apply(timeline.progress, _incoming!, _outgoing!);
    });
  }

  /// Swaps to the group named [name], playing [transition] over the default.
  /// Mid-flight, naming the group being left reverses the swap, naming the
  /// current target keeps it running forward, and naming a third group
  /// completes the running swap first.
  ///
  /// Callable before mounting.
  void show(T name, {Transition? transition}) {
    final target = _group(name);
    assert(target != null, 'No group is named "$name".');

    if (_transition != null) {
      if (name == shown) {
        _forward = true;
        return;
      }

      if (identical(target, _outgoing)) {
        _shown = name;
        _forward = false;
        return;
      }

      _settle(loser: (_forward ? _outgoing : _incoming)!);
    }

    if (name == shown) return;
    _swap(target!, transition);
  }

  TransitionGroupNode<T>? _group(T name) {
    for (final group in _groups) {
      if (group.name == name) return group;
    }

    return null;
  }

  void _swap(TransitionGroupNode<T> incoming, Transition? transition) {
    final outgoing = _group(shown)!;
    incoming.enable();
    outgoing.priority = 0;
    incoming.priority = 1;
    _outgoing = outgoing;
    _incoming = incoming;
    _shown = incoming.name;
    _forward = true;

    final flight = transition ?? this.transition;
    _transition = flight;
    flight.timeline.setToStart();
    flight.apply(flight.timeline.progress, incoming, outgoing);
    final chrome = flight.chrome;
    if (chrome == null) return;
    chrome.priority = 2;
    chrome.enable();
    add(chrome);
  }

  @internal
  void register(TransitionGroupNode<T> group) {
    assert(
      _groups.where((other) => other.name == group.name).length == 1,
      'A group is already named "${group.name}".',
    );

    _shown ??= group.name;
    if (identical(group, _incoming) || identical(group, _outgoing)) return;
    group.enabled = group.name == _shown;
  }

  @internal
  void unregister(TransitionGroupNode<T> group) {
    if (identical(group, _incoming) || identical(group, _outgoing)) {
      _settle(loser: group);
    }
  }

  void _settle({required TransitionGroupNode<T> loser}) {
    final flight = _transition;
    if (flight == null) return;
    final incoming = _incoming!;
    final outgoing = _outgoing!;
    _transition = null;
    _incoming = null;
    _outgoing = null;
    incoming.reset();
    outgoing.reset();
    loser.disable();
    final chrome = flight.chrome;
    if (chrome == null) return;
    chrome.disable();
    remove(chrome);
  }
}
