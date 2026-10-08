// SPDX-AI-Disclosure: none

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:ignis/src/core.dart';
import 'package:ignis/src/message.dart';
import 'package:ignis/src/scene.dart';

/// Something a device emits: a key going down, a button pressed, a stick moved.
abstract interface class Trigger {
  /// Whether this, as a matcher bound to a node, accepts [trigger].
  bool accepts(Trigger trigger);
}

/// A source of triggers.
///
/// A subclass hooks its platform listeners up in [start], tears them down in
/// [stop], and calls [emit] for every trigger they turn into.
abstract base class ControlDevice {
  bool Function(Trigger trigger)? _dispatch;

  /// Whether this device has been started and not yet stopped.
  bool get isStarted => _dispatch != null;

  /// Starts listening to whatever this device draws its events from.
  @visibleForOverriding
  void start();

  /// Stops listening, undoing [start].
  @visibleForOverriding
  void stop();

  /// Dispatches [trigger], reporting whether anything answered it.
  @protected
  bool emit(Trigger trigger) {
    final dispatch = _dispatch;
    if (dispatch == null) return false;
    return dispatch(trigger);
  }

  /// Runs [start], unless this device is already started.
  void _start(bool Function(Trigger trigger) dispatch) {
    if (_dispatch != null) return;
    _dispatch = dispatch;
    start();
  }

  /// Runs [stop], unless this device is already stopped.
  void _stop() {
    if (_dispatch == null) return;
    _dispatch = null;
    stop();
  }
}

/// Represents a single bound node, alongside any metadata needed to match it.
class _Binding {
  /// What answers the triggers.
  final Node node;

  /// What the node is told was asked for.
  final Object action;

  /// The triggers the node responds to. At least one must be satisfied.
  final Set<Trigger> matchers;

  /// The groups gating the node. If not empty, at least one must be enabled.
  final Set<String> groups;

  const _Binding(this.node, this.action, this.matchers, this.groups);
}

/// Routes triggers to nodes registered with [bind].
///
/// This class essentially has two sides, one meant for [ControlDevice]s and
/// another meant for bound nodes.
///
/// A [ControlDevice] is usually a singleton that hooks into hardware or another
/// globally shared resource, then funnels triggers into this class. Devices use
/// [install] and [uninstall] to register themselves. Internally, it will then
/// translate any device events into calls to [dispatch].
///
/// There is only one device built into vanilla Ignis: the `KeyboardDevice`.
///
/// Meanwhile, [bind] allows any number of nodes to respond to those triggers as
/// a [Control]. Its parameters provide additional features for managing
/// precisely when the node is permitted to respond, and to which specific
/// triggers.
///
/// User code is welcome to call [dispatch] manually to simulate or test
/// triggers that would normally come from a device.
class Controls {
  final List<_Binding> _bindings = [];
  final Set<String> _disabled = {};
  final List<ControlDevice> _devices = [];

  /// The devices feeding triggers in.
  List<ControlDevice> get devices => UnmodifiableListView(_devices);

  /// Starts [device] and feeds its triggers to [dispatch], until [uninstall]ed.
  void install(ControlDevice device) {
    if (_devices.contains(device)) return;
    _devices.add(device);
    device._start(dispatch);
  }

  /// Stops [device] and drops it.
  void uninstall(ControlDevice device) {
    if (!_devices.remove(device)) return;
    device._stop();
  }

  /// Answers any of [matchers] by processing a [Control] carrying [action] on
  /// [node], until [release]d.
  ///
  /// Where several live nodes match one trigger the topmost node wins and the
  /// rest never run, as a hit test would pick it.
  ///
  /// If [groups] has any names, at least one of those groups must be enabled
  /// in order for the node to respond. Use [enable] and [disable] to manage
  /// the enabled names.
  void bind(
    Node node,
    Object action, {
    required Set<Trigger> matchers,
    Set<String> groups = const {},
  }) {
    final binding = _Binding(
      node,
      action,
      .of(matchers),
      .of(groups),
    );

    _bindings.add(binding);
  }

  /// Drops every bind made for [node].
  void release(Node node) {
    _bindings.removeWhere((binding) => identical(binding.node, node));
  }

  /// Lets the nodes in [group] answer again.
  void enable(String group) => _disabled.remove(group);

  /// Stops the nodes in [group] answering, until [enable].
  void disable(String group) => _disabled.add(group);

  /// Whether [group] is enabled, which it is until [disable].
  bool isEnabled(String group) => !_disabled.contains(group);

  /// Tells the one node that answers [emitted], if any.
  ///
  /// Returns whether anything ran, so a device can report the event as handled.
  bool dispatch(Trigger emitted) {
    List<_Binding>? matched;

    for (final binding in _bindings) {
      if (!_eligible(binding)) continue;
      if (!binding.matchers.any((matcher) => matcher.accepts(emitted))) continue;
      (matched ??= []).add(binding);
    }

    if (matched == null) return false;
    final winner = _winner(matched);
    if (winner == null) return false;

    winner.node.post(Control(winner.action, emitted));
    return true;
  }

  /// Whether [binding] is in no group, or in one that is enabled.
  bool _eligible(_Binding binding) {
    if (_disabled.isEmpty || binding.groups.isEmpty) {
      return true;
    }

    for (final group in binding.groups) {
      if (!_disabled.contains(group)) {
        return true;
      }
    }

    return false;
  }

  /// Picks the winning [matched] binding by looking through each active scene.
  _Binding? _winner(List<_Binding> matched) {
    for (final scene in Scene.ACTIVE) {
      for (final node in scene.root.traverse(prune: (node) => !node.activity.inputs)) {
        for (final binding in matched.reversed) {
          if (identical(binding.node, node)) {
            return binding;
          }
        }
      }
    }

    return null;
  }

  /// Stops every device and drops every binding.
  void dispose() {
    for (final device in _devices) {
      device._stop();
    }

    _devices.clear();
    _bindings.clear();
    _disabled.clear();
  }
}

/// Emitted to a bound node when a device emits a [trigger] its bind matches.
final class Control extends Message {
  /// What the bind was made for.
  final Object action;

  /// What the device emitted.
  final Trigger trigger;

  const Control(this.action, this.trigger);
}
