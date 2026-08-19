part of 'core.dart';

/// Something a device emits: a key going down, a button pressed, a stick moved.
///
/// The same type describes both halves of a match: [accepts] is asked of the
/// one bound to an action and handed the one a device emitted. What counts as
/// a match is each event's own business, so a bound event is free to be looser
/// than the one that meets it.
///
/// Kept open rather than sealed: a keyboard is the only device the engine
/// ships for, but a gamepad or a plugin's device can emit events of its own and
/// have them dispatched without [Controls] knowing what they are.
abstract interface class ControlEvent {
  /// Whether this event, as something bound to an action, accepts [emitted].
  bool accepts(ControlEvent emitted);
}

/// States that an action has been fired, along with any other context.
final class ControlReport<T extends Object> {
  /// The action that fired.
  final T action;

  /// What fired it, or null where [Controls.fire] ran the action outright.
  final ControlEvent? event;

  const ControlReport._(this.action, [this.event]);
}

/// Responds to reports of a particular type of action.
typedef ControlHandler<T extends Object> = void Function(ControlReport<T> report);

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

/// One handler's claim on an action.
class _Claim {
  /// The node whose build made this claim, or null where nothing was building.
  final Node? node;

  /// The handler, with the action's type closed over, so one list can hold
  /// claims on actions of every type at once.
  final void Function(Object action, ControlEvent? event) run;

  const _Claim(this.node, this.run);
}

/// Routes events emitted by control devices to registered handlers.
///
/// An action is any value that hashes and compares by value: an enum member, a
/// string, a class a game builds at runtime out of whatever names an action to
/// it. The engine never reads one, only matches it.
///
/// TODO: Document further.
class Controls {
  final Map<Object, Set<ControlEvent>> _events = {};
  final Map<Object, List<_Claim>> _claims = {};

  final List<ControlDevice> _devices = [];

  /// The devices feeding events in.
  List<ControlDevice> get devices => UnmodifiableListView(_devices);

  /// Starts [device] and feeds its events to [dispatch], until [detach]ed.
  void attach(ControlDevice device) {
    if (_devices.contains(device)) return;
    _devices.add(device);
    device._start(dispatch);
  }

  /// Stops [device] and drops it.
  void detach(ControlDevice device) {
    if (!_devices.remove(device)) return;
    device._stop();
  }

  /// Assigns [events] to [action], replacing whatever it had.
  void bind(Object action, Set<ControlEvent> events) {
    _events[action] = {...events};
  }

  /// Drops every event assigned to [action].
  void unbind(Object action) {
    _events.remove(action);
  }

  /// The events assigned to [action], empty if it has none.
  Set<ControlEvent> eventsFor(Object action) {
    return UnmodifiableSetView(_events[action] ?? const {});
  }

  /// Every assignment, for a screen that lists them. Read-only.
  Map<Object, Set<ControlEvent>> get bindings {
    return UnmodifiableMapView({
      for (final entry in _events.entries) //
        entry.key: UnmodifiableSetView(entry.value),
    });
  }

  /// Answers [action] with [handler] until the returned [Cleanup] is called,
  /// or until the [Node.build] that made it is gone.
  ///
  /// Where several claims are live on one action the topmost node wins, as a
  /// hit test would pick it. [matchers] assigns what fires the action for
  /// exactly as long as the claim lasts, putting back whatever it displaced.
  Cleanup claim<T extends Object>(
    T action,
    ControlHandler<T> handler, {
    Set<ControlEvent> matchers = const {},
  }) {
    final claims = _claims[action] ??= [];
    final claim = _Claim(Node._builder, (fired, event) {
      return handler(ControlReport<T>._(fired as T, event));
    });

    claims.add(claim);

    // TODO: Refactor this spaghetti.

    void release() {
      if (!claims.remove(claim)) return;
      if (claims.isEmpty) _claims.remove(action);
    }

    if (matchers.isEmpty) return _trash(release);

    final displaced = _events[action];
    bind(action, matchers);

    return _trash(() {
      if (displaced == null) {
        _events.remove(action);
      } else {
        _events[action] = displaced;
      }

      release();
    });
  }

  /// Runs the winning claim of every action [emitted] fires.
  ///
  /// Returns whether anything ran, so a device can report the event as
  /// handled.
  ///
  /// Every action is matched before any handler runs, so a handler is free to
  /// bind and unbind as it answers: a press is judged against the bindings as
  /// they stood when it arrived, not as it leaves them.
  bool dispatch(ControlEvent emitted) {
    List<Object>? fired;

    for (final entry in _events.entries) {
      if (!entry.value.any((bound) => bound.accepts(emitted))) continue;
      (fired ??= []).add(entry.key);
    }

    if (fired == null) return false;
    var handled = false;

    for (final action in fired) {
      if (fire(action, emitted)) {
        handled = true;
      }
    }

    return handled;
  }

  /// Runs the winning claim on [action], whatever is bound to it.
  ///
  /// How a button on screen, a script or a console reaches an action with no
  /// device in the middle, and the only way to reach one nothing is bound to.
  /// Returns whether anything ran.
  ///
  /// [event] is what set the action off, and reaches the handler on its
  /// [ControlReport]. [dispatch] passes whatever the device emitted; a caller
  /// firing an action itself can make one up to say where it came from, and
  /// leave it out where there is nothing worth saying.
  bool fire(Object action, [ControlEvent? event]) {
    final winner = _winner(action);
    if (winner == null) return false;
    winner.run(action, event);
    return true;
  }

  /// The claim on [action] that answers it, by tree order.
  ///
  /// Walks the live scenes exactly as a hit test would, and takes the first
  /// claim whose node it reaches, so a claim the walk never reaches never runs.
  /// Claims with no node rank below every node, the most recent of them first.
  _Claim? _winner(Object action) {
    final claims = _claims[action];
    if (claims == null || claims.isEmpty) return null;

    if (claims.any((claim) => claim.node != null)) {
      for (final scene in Scene.live) {
        for (final node in _topmost(scene.node)) {
          for (final claim in claims.reversed) {
            if (identical(claim.node, node)) return claim;
          }
        }
      }
    }

    for (final claim in claims.reversed) {
      if (claim.node == null) return claim;
    }

    return null;
  }

  /// [node] and its subtree, topmost first, the way a hit test walks it.
  Iterable<Node> _topmost(Node node) sync* {
    if (!node.enabled) return;
    final children = node._egg?.nodes;

    if (children != null && children.isNotEmpty) {
      for (final child in children.reversed) {
        yield* _topmost(child);
      }
    }

    yield node;
  }

  /// Stops every device, and drops every binding and claim.
  void dispose() {
    for (final device in _devices) {
      device._stop();
    }

    _devices.clear();
    _events.clear();
    _claims.clear();
  }
}
