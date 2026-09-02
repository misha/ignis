// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/effects/interfaces/measurable_effect.dart';
import 'package:ignis/src/nodes/effect_node.dart';
import 'package:ignis/src/timeline.dart';

/// An effect driven by a [Timeline].
class TimelineEffect extends EffectNode {
  /// Drives this effect.
  final Timeline timeline;

  /// Emitted once, when this effect starts progressing.
  final onStart = Signal0();

  /// Emitted after each update once this effect starts progressing, with its
  /// current progress.
  final onProgress = Signal1<double>();

  /// Emitted each time [progress] reaches 1.
  final onMax = Signal0();

  /// Emitted each time [progress] reaches 0.
  final onMin = Signal0();

  double _previousProgress = 0;
  bool _started = false;
  bool _finished = false;
  bool _forward = true;
  bool _fitted = false;

  /// This effect's progress as of the previous [onProgress] emission.
  double get previousProgress => _previousProgress;

  /// This effect's current progress.
  double get progress => timeline.progress;

  /// Whether this effect has started progressing.
  bool get isRunning => _started;

  /// Whether this effect has finished and no longer needs updating.
  bool get isFinished => _finished;

  /// Whether this effect is running in the forward direction.
  bool get isForward => _forward;

  /// Whether this effect is running in the reverse direction.
  bool get isReverse => !_forward;

  @visibleForTesting
  TimelineEffect({
    required this.timeline,
    super.cleanup,
    super.enabled,
    super.priority,
    super.children,
  });

  /// Run this effect in its forward direction.
  ///
  /// If the effect was disabled, it is automatically [enabled].
  void forward() {
    _forward = true;
    enabled = true;
  }

  /// Run this effect in its reverse direction.
  ///
  /// If the effect was disabled, it is automatically [enabled].
  void reverse() {
    _forward = false;
    enabled = true;
  }

  @override
  void reset() {
    timeline.setToStart();
    _previousProgress = 0;
    _started = false;
    _finished = false;
    _forward = true;
  }

  @override
  void build() {
    super.build();

    tick((dt) {
      if (!_fitted) {
        _fitted = true;

        if (this case final MeasurableEffect measurable) {
          timeline.fit(measurable.measure());
        }
      }

      if (_forward) {
        timeline.advance(dt);
      } else {
        timeline.recede(dt);
      }

      if (!timeline.hasStarted) {
        _started = false;
        return;
      }

      if (!_started) {
        _started = true;
        onStart.emit();
      }

      final progress = timeline.progress;

      if (progress == 1 && _previousProgress != 1) {
        onMax.emit();
      }

      if (progress == 0 && _previousProgress != 0) {
        onMin.emit();
      }

      onProgress.emit(progress);
      _previousProgress = progress;

      if (!timeline.isFinished) {
        _finished = false;
        return;
      }

      if (_finished) {
        return;
      }

      _finished = true;
      onFinish.emit();
    });
  }
}
