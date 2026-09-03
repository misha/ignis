// SPDX-AI-Disclosure: none

part of 'core.dart';

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
  ///
  /// The answer is what a platform listener wants back, to say whether what it
  /// delivered was handled. Dispatches nothing while stopped, so a listener
  /// that outlives [stop] is inert rather than wrong.
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

/// One handler, the events that reach it, and the groups that gate it.
class _Control {
  /// What answers the events.
  final ControlHandler handler;

  /// The events it answers, any one of which is enough.
  final Set<ControlEvent> matchers;

  /// The groups gating it, empty where nothing does.
  final Set<String> groups;

  /// The node whose build bound this, or null where nothing was building.
  final Node? node;

  const _Control(this.handler, this.matchers, this.groups, this.node);
}

/// Routes events emitted by control devices to the handlers bound to them.
///
/// One call binds the lot: the events that reach a handler, the handler, and
/// any groups that switch it on and off. There is nothing else to register and
/// no name in the middle, so a control is one thing in one place.
///
/// TODO: Document further.
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

  /// Answers any of [matchers] with [handler], until the returned [Cleanup] is
  /// called or the [Node.build] that bound it is gone.
  ///
  /// Where several live handlers match one event the topmost node wins and the
  /// rest never run, as a hit test would pick it.
  ///
  /// [groups] gates the handler: it answers if at least one group is enabled.
  /// If [groups] is empty, it always answers.
  Cleanup bind(
    ControlHandler handler, {
    required Set<ControlEvent> matchers,
    Set<String> groups = const {},
  }) {
    final control = _Control(
      handler,
      .of(matchers),
      .of(groups),
      Node._builder,
    );

    _controls.add(control);
    return _trash(() => _controls.remove(control));
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
  ///
  /// Every match is found before the winner runs, so a handler is free to bind
  /// and unbind as it answers: a press is judged against the controls as they
  /// stood when it arrived, not as it leaves them.
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

  /// The one of [matched] that answers, by tree order.
  ///
  /// Walks the live scenes exactly as a hit test would, and takes the first
  /// whose node it reaches, so a handler the walk never reaches never runs.
  /// Handlers with no node rank below every node, the most recent of them
  /// first.
  _Control? _winner(List<_Control> matched) {
    if (matched.any((control) => control.node != null)) {
      for (final scene in Scene.live) {
        for (final node in _topmost(scene.node)) {
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

  /// [node] and its subtree, topmost first, the way a hit test walks it.
  Iterable<Node> _topmost(Node node) sync* {
    if (!node.activity.inputs) return;
    final children = node._egg?.nodes;

    if (children != null && children.isNotEmpty) {
      for (final child in children.reversed) {
        yield* _topmost(child);
      }
    }

    yield node;
  }

  /// Stops every device, and drops every control.
  void dispose() {
    for (final device in _devices) {
      device._stop();
    }

    _devices.clear();
    _controls.clear();
    _disabled.clear();
  }
}
