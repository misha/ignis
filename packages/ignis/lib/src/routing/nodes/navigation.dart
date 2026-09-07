part of 'router_node.dart';

sealed class _Navigation {
  final Transition transition;
  final Completer<void> settled;
  final RouteNode incoming;

  _Navigation(
    this.transition, {
    required this.settled,
    required this.incoming,
  });

  /// How far the clock has run.
  double get progress => transition.timeline.progress;

  /// Sets the clock to the end this navigation runs from.
  void start() => transition.timeline.setToStart();

  /// Moves the clock by [dt], reporting whether this navigation has landed.
  bool step(double dt) {
    final timeline = transition.timeline;
    timeline.advance(dt);
    return timeline.isFinished;
  }

  /// Poses every side at [progress].
  void pose();

  /// Returns every side to how it stands outside a navigation.
  void rest();

  /// What [route] takes part in as a side of this navigation, or null when it
  /// is not one.
  Activity? activityOf(RouteNode route);

  /// The routes on [stack] that leave it once this navigation settles.
  Iterable<RouteNode> leaving(Iterable<RouteNode> stack);
}

final class _Swap extends _Navigation {
  final RouteNode outgoing;

  _Swap(
    super.transition, {
    required super.settled,
    required super.incoming,
    required this.outgoing,
  });

  @override
  void pose() {
    transition.apply(progress, incoming, outgoing);
  }

  @override
  void rest() {
    incoming._reset();
    outgoing._reset();
  }

  @override
  Activity? activityOf(RouteNode route) {
    if (identical(route, incoming)) return transition.incoming;
    if (identical(route, outgoing)) return transition.outgoing;
    return null;
  }

  /// A swap leaves nothing behind: whichever side lost goes, and so does
  /// everything the arriving side was laid over.
  @override
  Iterable<RouteNode> leaving(Iterable<RouteNode> stack) {
    return stack.where((route) => !identical(route, incoming));
  }
}

final class _Layer extends _Navigation {
  final RouteNode covered;
  final Backdrop backdrop;

  /// Which way the clock runs. Only a push turns around, when the pop that
  /// matches it lands before it has.
  bool forward;

  _Layer(
    super.transition, {
    required super.settled,
    required super.incoming,
    required this.covered,
    required this.backdrop,
    bool? forward,
  }) : forward = forward ?? true;

  /// Turns the push around to play back, reporting whether it was still
  /// playing forward.
  bool turn() {
    if (!forward) return false;
    forward = false;
    return true;
  }

  @override
  void start() {
    if (forward) {
      transition.timeline.setToStart();
    } else {
      transition.timeline.setToEnd();
    }
  }

  @override
  bool step(double dt) {
    final timeline = transition.timeline;

    if (forward) {
      timeline.advance(dt);
      return timeline.isFinished;
    }

    timeline.recede(dt);
    return timeline.progress == 0 || timeline.duration == 0;
  }

  @override
  void pose() {
    transition.apply(progress, incoming, null);
    backdrop.apply(progress, covered);
  }

  @override
  void rest() {
    incoming._reset();
    covered._reset();
  }

  @override
  Activity? activityOf(RouteNode route) {
    if (identical(route, incoming)) return transition.incoming;
    if (identical(route, covered)) return backdrop.running & ~Activity.input;
    return null;
  }

  @override
  Iterable<RouteNode> leaving(Iterable<RouteNode> stack) => forward ? const [] : [incoming];
}
