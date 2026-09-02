// SPDX-AI-Disclosure: none

import 'package:ignis/src/timeline.dart';

/// Runs [child] once; ignored after that, whether reversing or repeating.
class OnceTimeline extends Timeline {
  /// The timeline run once.
  final Timeline child;

  OnceTimeline(this.child);

  @override
  void fit(double distance) => child.fit(distance);

  @override
  double? get duration => child.duration;

  @override
  bool get hasStarted => child.isFinished;

  @override
  bool get isFinished => child.isFinished;

  @override
  double get progress => child.progress;

  @override
  double advance(double dt) => child.advance(dt);

  @override
  double recede(double dt) => child.isFinished ? dt : child.recede(dt);

  @override
  void setToStart() {
    if (!child.isFinished) child.setToStart();
  }

  @override
  void setToEnd() => child.setToEnd();
}
