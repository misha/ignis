// SPDX-AI-Disclosure: none

import 'package:ignis/src/timeline.dart';

/// Runs [child] [times] times before finishing, restarting it from the
/// beginning after each completed run.
class RepeatTimeline extends Timeline {
  /// The timeline run repeatedly.
  final Timeline child;

  /// How many times to run [child] before finishing.
  final int times;

  int _remaining;

  RepeatTimeline(this.child, this.times)
    : assert(times > 0, 'Times must be positive.'),
      assert(!child.isInfinite, 'Cannot repeat an infinite timeline.'),
      _remaining = times;

  @override
  void fit(double distance) => child.fit(distance);

  @override
  double? get duration {
    final duration = child.duration;
    if (duration == null) return null;
    return duration * times;
  }

  @override
  bool get hasStarted => child.hasStarted;

  @override
  bool get isFinished => _remaining == 0;

  @override
  double get progress => child.progress;

  @override
  double advance(double dt) {
    var overflow = child.advance(dt);

    while (overflow > 0 && _remaining > 0) {
      _remaining -= 1;

      if (_remaining != 0) {
        child.setToStart();
        overflow = child.advance(overflow);
      }
    }

    if (_remaining == 1 && child.isFinished) _remaining -= 1;
    return overflow;
  }

  @override
  double recede(double dt) {
    var remaining = child.recede(dt);

    while (remaining > 0 && _remaining < times) {
      _remaining += 1;
      child.setToEnd();
      remaining = child.recede(remaining);
    }

    return remaining;
  }

  @override
  void setToStart() {
    child.setToStart();
    _remaining = times;
  }

  @override
  void setToEnd() {
    child.setToEnd();
    _remaining = 0;
  }
}
