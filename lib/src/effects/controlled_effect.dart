import 'package:ignis/src/effect_controller.dart';
import 'package:ignis/src/nodes/effect_node.dart';
import 'package:ignis/src/signal.dart';

/// An effect that progresses over time, driven by its [EffectController].
class ControlledEffect extends EffectNode {
  /// Drives this effect's timing and progress.
  final EffectController controller;

  /// Whether to [detach] once finished. Defaults to false.
  bool cleanup;

  /// Emitted each time this effect starts progressing from position 0,
  /// before the first [onProgress] emission of that run.
  final onStart = Signal0();

  /// Emitted after each update once this effect starts progressing, with its
  /// current progress.
  final onProgress = Signal1<double>();

  double _previousProgress = 0;
  bool _started = false;
  bool _paused = false;
  bool _finished = false;
  bool _forward = true;

  /// This effect's progress as of the previous [onProgress] emission.
  double get previousProgress => _previousProgress;

  /// Whether this effect has started progressing.
  bool get isRunning => _started;

  /// Whether this effect is currently paused.
  bool get isPaused => _paused;

  /// Whether this effect has finished and no longer needs updating.
  bool get isFinished => _finished;

  /// Whether this effect is running in the forward direction.
  bool get isForward => _forward;

  /// Whether this effect is running in the reverse direction.
  bool get isReverse => !_forward;

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

  /// Run this effect in its forward direction.
  void forward() => _forward = true;

  /// Run this effect in its reverse direction.
  void reverse() => _forward = false;

  @override
  void reset() {
    controller.setToStart();
    _previousProgress = 0;
    _paused = false;
    _started = false;
    _finished = false;
    _forward = true;
  }

  @override
  void tick(double dt) {
    if (_paused) {
      return;
    }

    final double overflow;

    if (_forward) {
      overflow = controller.advance(dt);
    } else {
      overflow = controller.recede(dt);
    }

    if (!controller.hasStarted) {
      _started = false;
      return;
    }

    if (!_started) {
      _started = true;
      onStart.emit();
    }

    final progress = controller.progress;
    onProgress.emit(progress);
    _previousProgress = progress;

    if (!controller.isFinished) {
      _finished = false;
      return;
    }

    if (_finished) {
      return;
    }

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
