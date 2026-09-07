part of 'router_node.dart';

/// One run of a [transition], carrying [incoming] against whatever it plays
/// over. Made at the end it runs from with its sides taking part as it says,
/// ticked and settled by its router.
sealed class _Navigation {
  final Transition transition;
  final RouteNode incoming;

  /// Which way the clock runs. Turns around when a pop lands before it has.
  bool forward;

  /// Completes once this navigation settles.
  final settled = Completer<void>();

  _Navigation(
    this.transition, {
    required this.incoming,
    bool? forward,
  }) : forward = forward ?? true {
    if (this.forward) {
      transition.timeline.setToStart();
    } else {
      transition.timeline.setToEnd();
    }
  }

  /// How far the clock has run.
  double get progress => transition.timeline.progress;

  /// Turns this navigation around to play back, reporting whether it was
  /// still playing forward.
  bool turn() {
    if (!forward) return false;
    forward = false;
    return true;
  }

  /// Moves the clock by [dt] and poses every side, reporting whether this
  /// navigation has landed. Holds while [incoming] is on its way to the tree.
  bool tick(double dt) {
    if (!incoming.isMounted) return false;
    final timeline = transition.timeline;
    final bool landed;

    if (forward) {
      timeline.advance(dt);
      landed = timeline.isFinished;
    } else {
      timeline.recede(dt);
      // A clock with no length has nowhere to recede to.
      landed = timeline.progress == 0 || timeline.duration == 0;
    }

    _pose();
    return landed;
  }

  /// Returns every side to how it stands once this navigation is over, and
  /// completes [settled].
  void settle() {
    _rest();
    settled.complete();
  }

  /// The routes on [stack] that leave it once this navigation settles.
  Iterable<RouteNode> leaving(Iterable<RouteNode> stack);

  /// Poses every side at [progress].
  void _pose();

  /// Returns every side to how it stands once this navigation is over.
  void _rest();
}

final class _Swap extends _Navigation {
  final RouteNode? outgoing;

  _Swap(
    super.transition, {
    required super.incoming,
    required this.outgoing,
  }) {
    incoming.activity = transition.incoming;
    outgoing?.activity = transition.outgoing;
  }

  @override
  void _pose() {
    transition.apply(progress, incoming, outgoing);
  }

  @override
  void _rest() {
    incoming
      .._reset()
      ..activity = .all;

    outgoing
      ?.._reset()
      ..activity = .all;
  }

  /// A swap played forward leaves nothing behind: whichever side lost goes,
  /// and so does everything the arriving side was laid over. Played back, the
  /// arriving side goes instead.
  @override
  Iterable<RouteNode> leaving(Iterable<RouteNode> stack) {
    if (!forward) return [incoming];
    return stack.where((route) => !identical(route, incoming));
  }
}

final class _Layer extends _Navigation {
  final RouteNode? covered;
  final Backdrop backdrop;

  _Layer(
    super.transition, {
    required super.incoming,
    required this.covered,
    required this.backdrop,
    super.forward,
  }) {
    incoming.activity = transition.incoming;
    covered?.activity = backdrop.running & ~Activity.input;
  }

  @override
  void _pose() {
    transition.apply(progress, incoming, null);
    final covered = this.covered;
    if (covered != null) backdrop.apply(progress, covered);
  }

  @override
  void _rest() {
    incoming
      .._reset()
      ..activity = .all;

    final covered = this.covered;
    if (covered == null) return;
    covered._reset();
    covered.activity = forward ? backdrop.settled & ~Activity.input : .all;
  }

  @override
  Iterable<RouteNode> leaving(Iterable<RouteNode> stack) => forward ? const [] : [incoming];
}
