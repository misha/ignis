// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
import 'package:ignis/src/effects/interfaces/measurable_effect.dart';
import 'package:ignis/src/message.dart';
import 'package:ignis/src/nodes/effect_node.dart';
import 'package:ignis/src/timeline.dart';

/// An effect driven by a [Timeline].
class TimelineEffect extends EffectNode {
  /// Drives this effect.
  final Timeline timeline;

  double _previousProgress = 0;
  bool _started = false;
  bool _finished = false;
  bool _forward = true;
  bool _fitted = false;

  /// This effect's progress before the latest [Update].
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
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Update(:final dt):
        if (!_fitted) {
          _fitted = true;

          if (this case final MeasurableEffect measurable) {
            timeline.fit(measurable.measure());
          }
        }

        _previousProgress = timeline.progress;

        if (_forward) {
          timeline.advance(dt);
        } else {
          timeline.recede(dt);
        }

        if (!timeline.hasStarted) {
          _started = false;
          break;
        }

        if (!_started) {
          _started = true;
          parent?.post(TimelineStart(this));
        }

        final progress = timeline.progress;

        if (progress == 1 && _previousProgress != 1) {
          parent?.post(TimelineMax(this));
        }

        if (progress == 0 && _previousProgress != 0) {
          parent?.post(TimelineMin(this));
        }

        parent?.post(TimelineProgress(this, progress));

        if (!timeline.isFinished) {
          _finished = false;
          break;
        }

        if (_finished) {
          break;
        }

        _finished = true;
        finish();
    }
  }
}

/// Emitted once, when [effect] starts progressing.
final class TimelineStart extends Message {
  final TimelineEffect effect;

  const TimelineStart(this.effect);
}

/// Emitted after each update once [effect] starts progressing, with its
/// current progress.
final class TimelineProgress extends Message {
  final TimelineEffect effect;

  final double progress;

  const TimelineProgress(this.effect, this.progress);
}

/// Emitted each time [effect]'s progress reaches 1.
final class TimelineMax extends Message {
  final TimelineEffect effect;

  const TimelineMax(this.effect);
}

/// Emitted each time [effect]'s progress reaches 0.
final class TimelineMin extends Message {
  final TimelineEffect effect;

  const TimelineMin(this.effect);
}
