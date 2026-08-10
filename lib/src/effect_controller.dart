import 'package:flutter/animation.dart';
import 'package:ignis/src/effects/controlled_effect.dart';

/// Drives a [ControlledEffect]'s timing and progress over a fixed
/// [duration].
class EffectController {
  /// How long to run the effect from start to finish.
  final double duration;

  /// The curve to use when progressing the effect. Defaults to [Curves.linear].
  final Curve curve;

  /// How long to wait before starting the effect, the first time only.
  /// Defaults to 0.
  final double initialDelay;

  /// How long to pause at the bottom before each repeat's forward phase
  /// begins, after the first. Defaults to 0.
  final double bottomDelay;

  /// How long to pause at the top before the reverse phase starts, when
  /// [reverse] is true. Defaults to 0.
  final double topDelay;

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

  late final double _totalDuration;
  double _elapsed = 0;
  int _repeats = 0;
  bool _hasStartedOnce = false;

  /// Whether or not this effect has started.
  bool get hasStarted => _elapsed >= 0;

  /// Whether or not this effect has finished.
  bool get isFinished => _elapsed >= _totalDuration;

  /// Whether another repeat remains once the current one finishes.
  bool get canRepeat => times == null || _repeats + 1 < times!;

  double get _bottomFloor => -(_hasStartedOnce ? bottomDelay : initialDelay);

  EffectController({
    required this.duration,
    this.curve = Curves.linear,
    this.initialDelay = 0,
    this.bottomDelay = 0,
    this.topDelay = 0,
    this.times = 1,
    bool? reverse,
    double? reverseDuration,
    Curve? reverseCurve,
  }) : assert(duration > 0, 'Duration must be positive.'),
       assert(initialDelay >= 0, 'Initial delay cannot be negative.'),
       assert(bottomDelay >= 0, 'Bottom delay cannot be negative.'),
       assert(topDelay >= 0, 'Top delay cannot be negative.'),
       assert(times == null || times > 0, 'Times must be positive.'),
       assert(reverseDuration == null || reverseDuration > 0, 'Reverse duration must be positive.'),
       reverse = reverse ?? false,
       reverseDuration = reverseDuration ?? duration,
       reverseCurve = reverseCurve ?? curve,
       _elapsed = -initialDelay {
    var totalDuration = duration;
    if (this.reverse) totalDuration += topDelay + this.reverseDuration;
    _totalDuration = totalDuration;
  }

  double get progress {
    if (!hasStarted) return 0;
    if (_elapsed <= duration) return curve.transform(_elapsed / duration);
    if (_elapsed <= duration + topDelay) return 1;
    return 1 - reverseCurve.transform((_elapsed - duration - topDelay) / reverseDuration);
  }

  double advance(double dt) {
    assert(dt >= 0, 'Delta time cannot be negative.');
    _elapsed += dt;
    if (_elapsed >= 0) _hasStartedOnce = true;

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

    final floor = _bottomFloor;

    if (_elapsed < floor) {
      final remaining = floor - _elapsed;
      _elapsed = floor;
      return remaining;
    }

    return 0;
  }

  void setToStart() {
    _elapsed = -initialDelay;
    _repeats = 0;
    _hasStartedOnce = false;
  }

  void setToEnd() {
    _elapsed = _totalDuration;
    _hasStartedOnce = true;
  }

  /// Restarts this controller for its next repeat, carrying over [overflow]
  /// time advanced past the end of the run.
  void repeat([double overflow = 0]) {
    _repeats += 1;
    _elapsed = -bottomDelay + overflow;
  }
}
