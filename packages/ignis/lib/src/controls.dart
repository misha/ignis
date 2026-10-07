// SPDX-AI-Disclosure: none

import 'dart:collection';

import 'package:flutter/foundation.dart';

import 'package:ignis/src/core.dart';
import 'package:ignis/src/scene.dart';

/// Something a device emits: a key going down, a button pressed, a stick moved.
abstract interface class ControlEvent {
  /// Whether this event, as something bound to a handler, accepts [emitted].
  bool accepts(ControlEvent emitted);
}

/// Responds to an event a device emitted.
typedef ControlHandler = void Function(ControlEvent event);

/// A source of control events.
///
/// A subclass hooks its platform listeners up in [start], tears them down in
/// [stop], and calls [emit] for every event they turn into.
abstract base class ControlDevice {
  bool Function(ControlEvent event)? _dispatch;

  /// Whether this device has been started and not yet stopped.
  bool get isStarted => _dispatch != null;

  /// Starts listening to whatever this device draws its events from.
  @visibleForOverriding
  void start();

  /// Stops listening, undoing [start].
  @visibleForOverriding
  void stop();

  /// Dispatches [event], reporting whether anything answered it.
  @protected
  bool emit(ControlEvent event) {
    final dispatch = _dispatch;
    if (dispatch == null) return false;
    return dispatch(event);
  }

  /// Runs [start], unless this device is already started.
  void _start(bool Function(ControlEvent event) dispatch) {
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

/// Represents a single handler, alongside any metadata needed to match it.
class _Control {
  /// What answers the events.
  final ControlHandler handler;

  /// The events the handler respond to. At least one must be satisfied.
  final Set<ControlEvent> matchers;

  /// The groups gating the handler. If not empty, at least one must be enabled.
  final Set<String> groups;

  /// The node whose build bound this, or null where nothing was building.
  final Node? node;

  const _Control(this.handler, this.matchers, this.groups, this.node);
}

/// Routes control events to handlers registered with [bind].
///
/// This class essentially has two sides, one meant for [ControlDevice]s and
/// another meant for [ControlHandler]s.
///
/// A [ControlDevice] is usually a singleton that hooks into hardware or another
/// globally shared resource, then funnels events into this class. Devices use
/// [install] and [uninstall] to register themselves. Internally, it will then
/// translate any device events into calls to [dispatch].
///
/// There is only one device built into vanilla Ignis: the `KeyboardDevice`.
///
/// Meanwhile, [bind] allows any number of scenes to register a [ControlHandler]
/// to respond to those events. Its parameters provide additional features for
/// managing precisely when the handler is permitted to respond, and to which
/// specific control events.
///
/// User code is welcome to call [dispatch] manually to simulate or test events
/// that would normally come from a device.
class Controls {
  final List<_Control> _controls = [];
  final Set<String> _disabled = {};
  final List<ControlDevice> _devices = [];

  /// The devices feeding events in.
  List<ControlDevice> get devices => UnmodifiableListView(_devices);

  /// Starts [device] and feeds its events to [dispatch], until [uninstall]ed.
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

  /// Answers any of [matchers] with [handler], until the returned function is
  /// called or the [Node.build] that bound it is gone.
  ///
  /// Where several live handlers match one event the topmost node wins and the
  /// rest never run, as a hit test would pick it.
  ///
  /// If [groups] has any names, at least one of those groups must be enabled
  /// in order for the handler to respond. Use [enable] and [disable] to manage
  /// the enabled names.
  Cleanup bind(
    ControlHandler handler, {
    required Set<ControlEvent> matchers,
    Set<String> groups = const {},
  }) {
    final control = _Control(
      handler,
      .of(matchers),
      .of(groups),
      building,
    );

    _controls.add(control);
    return scope(() => _controls.remove(control));
  }

  /// Lets the handlers in [group] answer again.
  void enable(String group) => _disabled.remove(group);

  /// Stops the handlers in [group] answering, until [enable].
  void disable(String group) => _disabled.add(group);

  /// Whether [group] is enabled, which it is until [disable].
  bool isEnabled(String group) => !_disabled.contains(group);

  /// Runs the one handler that answers [emitted], if any.
  ///
  /// Returns whether anything ran, so a device can report the event as handled.
  bool dispatch(ControlEvent emitted) {
    List<_Control>? matched;

    for (final control in _controls) {
      if (!_eligible(control)) continue;
      if (!control.matchers.any((matcher) => matcher.accepts(emitted))) continue;
      (matched ??= []).add(control);
    }

    if (matched == null) return false;
    final winner = _winner(matched);
    if (winner == null) return false;

    winner.handler(emitted);
    return true;
  }

  /// Whether [control] is in no group, or in one that is enabled.
  bool _eligible(_Control control) {
    if (_disabled.isEmpty || control.groups.isEmpty) {
      return true;
    }

    for (final group in control.groups) {
      if (!_disabled.contains(group)) {
        return true;
      }
    }

    return false;
  }

  /// Picks the winning [matched] control by looking through each active scene.
  _Control? _winner(List<_Control> matched) {
    if (matched.any((control) => control.node != null)) {
      for (final scene in Scene.ACTIVE) {
        for (final node in scene.root.traverse(prune: (node) => !node.activity.inputs)) {
          for (final control in matched.reversed) {
            if (identical(control.node, node)) {
              return control;
            }
          }
        }
      }
    }

    for (final control in matched.reversed) {
      if (control.node == null) {
        return control;
      }
    }

    return null;
  }

  /// Stops every device and drops every control.
  void dispose() {
    for (final device in _devices) {
      device._stop();
    }

    _devices.clear();
    _controls.clear();
    _disabled.clear();
  }
}
