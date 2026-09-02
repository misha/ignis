// SPDX-AI-Disclosure: none

import 'package:flutter/animation.dart';
import 'package:ignis/src/timeline.dart';
import 'package:ignis/src/timelines/duration_timeline.dart';
import 'package:ignis/src/timelines/terminal_timeline.dart';

/// Progresses at [speed] units per second over the distance it is [fit] to,
/// shaped by [curve].
class SpeedTimeline extends Timeline {
  /// How fast to progress, in measured units per second.
  final double speed;

  /// Shapes progress over time. Defaults to [Curves.linear].
  final Curve curve;

  Timeline? _child;

  SpeedTimeline(this.speed, [Curve? curve])
    : assert(speed > 0, 'Speed must be positive.'),
      curve = curve ?? Curves.linear;

  @override
  void fit(double distance) {
    if (distance > 0) {
      _child = DurationTimeline(distance / speed, curve);
    } else {
      // A zero distance can't drive a curve; treat it as already finished.
      _child = const TerminalTimeline();
    }
  }

  Timeline get _fitted {
    final child = _child;

    if (child == null) {
      throw StateError(
        'SpeedTimeline needs a distance. '
        'Fit it before use.',
      );
    }

    return child;
  }

  @override
  double? get duration => _child?.duration;

  @override
  bool get hasStarted => _child?.hasStarted ?? false;

  @override
  bool get isFinished => _child?.isFinished ?? false;

  @override
  double get progress => _child?.progress ?? 0;

  @override
  double advance(double dt) => _fitted.advance(dt);

  @override
  double recede(double dt) => _fitted.recede(dt);

  @override
  void setToStart() => _child?.setToStart();

  @override
  void setToEnd() => _fitted.setToEnd();
}
