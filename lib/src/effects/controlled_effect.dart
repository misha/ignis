import 'package:ignis/src/effect_controller.dart';
import 'package:ignis/src/nodes/effect_node.dart';
import 'package:ignis/src/signal.dart';

/// An effect that progresses over time, driven by an [BaseEffectController].
class ControlledEffect<C extends BaseEffectController> extends EffectNode {
  /// Drives this effect's timing and progress.
  final C controller;

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
    controller.reset();
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

    final result = controller.update(dt);

    if (!controller.hasStarted) {
      return;
    }

    _emit(result.progress);

    if (result.repeat) {
      _previousProgress = 0;
      _started = false;
    } else if (result.finish && !_finished) {
      _finished = true;

      if (result.reset) {
        _started = false;
      }

      onFinish.emit();

      if (cleanup) {
        detach();
      }
    }
  }

  void _emit(double progress) {
    if (!_started) {
      _started = true;
      _finished = false;
      onStart.emit();
    }

    onProgress.emit(progress);
    _previousProgress = progress;
  }
}

/// Adds `play` to any [ControlledEffect] driven by a [ManualEffectController].
extension PlayableControlledEffect on ControlledEffect<ManualEffectController> {
  /// Plays this effect toward [to], a fraction of the controller's duration
  /// where 0 is the start and 1 is the end, starting from [from].
  ///
  /// Works for any sub-range, in either direction. Calling this again while
  /// already playing just redirects it, smoothly, from wherever it is.
  void play({
    double? from,
    required double to,
  }) {
    controller.play(from: from, to: to);

    if (from != null) {
      // Applies the jump immediately,
      _emit(controller.progress);
    }

    _finished = false;
  }
}
