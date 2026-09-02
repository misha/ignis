// SPDX-AI-Disclosure: none

import 'package:flutter/animation.dart';
import 'package:ignis/src/timelines/duration_timeline.dart';
import 'package:ignis/src/timelines/infinite_timeline.dart';
import 'package:ignis/src/timelines/once_timeline.dart';
import 'package:ignis/src/timelines/repeat_timeline.dart';
import 'package:ignis/src/timelines/roundtrip_timeline.dart';
import 'package:ignis/src/timelines/sequence_timeline.dart';
import 'package:ignis/src/timelines/speed_timeline.dart';
import 'package:ignis/src/timelines/terminal_timeline.dart';
import 'package:ignis/src/timelines/wait_timeline.dart';

/// A run of progress over time: how long it takes, how it is shaped, and how
/// it composes. Drives a `TimelineEffect` or a `Transition`.
abstract class Timeline {
  // #region API

  const Timeline();

  /// Tells this timeline how far its progress will carry, for one paced by
  /// speed. Composites pass it to their children; the rest ignore it.
  void fit(double distance) {
    // Nothing to do.
  }

  /// How long this timeline takes to complete, if known. `double.infinity`
  /// if it never completes on its own.
  double? get duration;

  /// Whether [duration] is `double.infinity`.
  bool get isInfinite => duration == double.infinity;

  /// Whether or not this timeline has started progressing.
  bool get hasStarted;

  /// Whether or not this timeline has finished.
  bool get isFinished;

  /// This timeline's current progress.
  double get progress;

  /// Advances this timeline's internal clock by [dt], returning any
  /// leftover time once finished.
  double advance(double dt);

  /// The reverse of [advance]: recedes this timeline's internal clock by
  /// [dt], returning any leftover time once back at the start.
  double recede(double dt);

  /// Resets this timeline back to its start.
  void setToStart();

  /// Jumps this timeline straight to its end.
  void setToEnd();

  // #endregion

  // #region Shorthand

  factory Timeline.duration(double duration, [Curve? curve]) = DurationTimeline;
  factory Timeline.infinite(Timeline child) = InfiniteTimeline;
  factory Timeline.once(Timeline child) = OnceTimeline;
  factory Timeline.repeat(Timeline child, int times) = RepeatTimeline;
  factory Timeline.roundtrip(Timeline child) = RoundtripTimeline;
  factory Timeline.sequence(List<Timeline> children) = SequenceTimeline;
  factory Timeline.speed(double speed, [Curve? curve]) = SpeedTimeline;
  factory Timeline.terminal() = TerminalTimeline;
  factory Timeline.wait(double duration) = WaitTimeline;

  // #endregion
}
