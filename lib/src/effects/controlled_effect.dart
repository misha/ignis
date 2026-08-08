import 'package:flutter/animation.dart';
import 'package:ignis/src/nodes/effect_node.dart';
import 'package:ignis/src/signal.dart';

/// An effect that progresses over time, driven by its [EffectController].
class ControlledEffect extends EffectNode {
  /// Drives this effect's timing and progress.
  final EffectController controller;

  /// Whether to [detach] once finished. Defaults to false.
  bool cleanup;

  /// Emitted once this effect starts progressing, before the first
  /// [onProgress] emission.
  final onStart = Signal0();

  /// Emitted after each update once this effect starts progressing, with its
  /// current progress.
  final onProgress = Signal1<double>();

  double _previousProgress = 0;
  bool _started = false;
  bool _paused = false;
  bool _finished = false;

  /// This effect's progress as of the previous [onProgress] emission.
  double get previousProgress => _previousProgress;

  /// Whether this effect has started progressing.
  bool get isRunning => _started;

  /// Whether this effect is currently paused.
  bool get isPaused => _paused;

  /// Whether this effect has finished and no longer needs updating.
  bool get isFinished => _finished;

  ControlledEffect({
    required this.controller,
    bool? cleanup,
    super.enabled,
    super.priority,
    super.children,
  }) : cleanup = cleanup ?? false;

  /// Pauses this effect, so it stops progressing until [resume]d.
  void pause() => _paused = true;

  /// Resumes this effect after a [pause].
  void resume() => _paused = false;

  @override
  void reset() {
    controller.setToStart();
    _previousProgress = 0;
    _paused = false;
    _started = false;
    _finished = false;
  }

  @override
  void tick(double dt) {
    if (_paused) {
      return;
    }

    final overflow = controller.advance(dt);

    if (!controller.hasStarted) {
      return;
    }

    if (!_started) {
      _started = true;
      onStart.emit();
    }

    final progress = controller.progress;
    onProgress.emit(progress);
    _previousProgress = progress;

    if (!_finished && controller.isFinished) {
      if (controller.canRepeat) {
        controller.repeat(overflow);
        _previousProgress = 0;
        _started = false;
        return;
      }

      _finished = true;
      onFinish.emit();

      if (cleanup) {
        detach();
      }
    }
  }
}

/// Drives a [ControlledEffect]'s timing and progress over a fixed
/// [duration].
class EffectController {
  /// How long to run the effect from start to finish.
  final double duration;

  /// The curve to use when progressing the effect. Defaults to [Curves.linear].
  final Curve curve;

  /// How long to wait before starting the effect. Defaults to 0.
  final double startDelay;

  /// How many times to run before [isFinished] stays true for good. Defaults
  /// to 1. Set to null to repeat forever.
  final int? times;

  /// Whether to run back from finish to start after reaching the end,
  /// before counting as one repeat. Defaults to false.
  final bool reverse;

  /// How long the reverse phase takes, when [reverse] is true. Defaults to
  /// [duration].
  final double reverseDuration;

  /// The curve to use for the reverse phase, when [reverse] is true.
  /// Defaults to [curve].
  final Curve reverseCurve;

  /// How long to pause at the end before the reverse phase starts, when
  /// [reverse] is true. Defaults to 0.
  final double reverseDelay;

  late final double _totalDuration;
  double _elapsed = 0;
  int _repeats = 0;

  /// Whether or not this effect has started.
  bool get hasStarted => _elapsed >= 0;

  /// Whether or not this effect has finished.
  bool get isFinished => _elapsed >= _totalDuration;

  /// Whether another repeat remains once the current one finishes.
  bool get canRepeat => times == null || _repeats + 1 < times!;

  EffectController({
    required this.duration,
    this.curve = Curves.linear,
    this.startDelay = 0,
    this.times = 1,
    bool? reverse,
    double? reverseDuration,
    Curve? reverseCurve,
    this.reverseDelay = 0,
  }) : assert(duration > 0, 'Duration must be positive.'),
       assert(startDelay >= 0, 'Start delay cannot be negative.'),
       assert(times == null || times > 0, 'Times must be positive.'),
       assert(reverseDuration == null || reverseDuration > 0, 'Reverse duration must be positive.'),
       assert(reverseDelay >= 0, 'Reverse delay cannot be negative.'),
       reverse = reverse ?? false,
       reverseDuration = reverseDuration ?? duration,
       reverseCurve = reverseCurve ?? curve,
       _elapsed = -startDelay {
    var totalDuration = duration;
    if (this.reverse) totalDuration += reverseDelay + this.reverseDuration;
    _totalDuration = totalDuration;
  }

  double get progress {
    if (!hasStarted) return 0;
    if (_elapsed <= duration) return curve.transform(_elapsed / duration);
    if (_elapsed <= duration + reverseDelay) return 1;
    return 1 - reverseCurve.transform((_elapsed - duration - reverseDelay) / reverseDuration);
  }

  double advance(double dt) {
    assert(dt >= 0, 'Delta time cannot be negative.');
    _elapsed += dt;

    if (_elapsed > _totalDuration) {
      final overflow = _elapsed - _totalDuration;
      _elapsed = _totalDuration;
      return overflow;
    }

    return 0;
  }

  double recede(double dt) {
    assert(dt >= 0, 'Delta time cannot be negative.');
    _elapsed -= dt;

    if (_elapsed < -startDelay) {
      final remaining = -startDelay - _elapsed;
      _elapsed = -startDelay;
      return remaining;
    }

    return 0;
  }

  void setToStart() {
    _elapsed = -startDelay;
    _repeats = 0;
  }

  void setToEnd() {
    _elapsed = _totalDuration;
  }

  /// Restarts this controller for its next repeat, carrying over [overflow]
  /// time advanced past the end of the run.
  void repeat([double overflow = 0]) {
    _repeats += 1;
    _elapsed = -startDelay + overflow;
  }
}
