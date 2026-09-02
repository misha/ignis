// SPDX-AI-Disclosure: none

import 'package:ignis/src/timelines/duration_timeline.dart';

/// Holds progress at 1 for [duration], without moving it. Used as a generic
/// mid-sequence pause.
class WaitTimeline extends DurationTimeline {
  WaitTimeline(super.duration);

  @override
  double get progress => 1;
}
