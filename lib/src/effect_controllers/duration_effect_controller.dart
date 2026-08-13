import 'package:flutter/animation.dart';
import 'package:ignis/src/effect_controller.dart';
import 'package:ignis/src/effects/controlled_effect.dart';

/// Progresses from 0 to 1 over [duration], shaped by [curve].
class DurationEffectController extends EffectController {
  /// How long this controller takes to complete.
  @override
  final double duration;

  /// The curve to shape progress with. Defaults to [Curves.linear].
  final Curve curve;

  double _elapsed;

  DurationEffectController(this.duration, [Curve? curve])
    : assert(duration > 0, 'Duration must be positive.'),
      curve = curve ?? Curves.linear,
      _elapsed = 0,
      super.empty();

  @override
  void attach(ControlledEffect effect) {
    // Nothing to do.
  }

  @override
  bool get hasStarted => true;

  @override
  bool get isFinished => _elapsed == duration;

  @override
  double get progress => curve.transform(_elapsed / duration);

  @override
  double advance(double dt) {
    assert(dt >= 0, 'Delta time cannot be negative.');
    _elapsed += dt;

    if (_elapsed > duration) {
      final overflow = _elapsed - duration;
      _elapsed = duration;
      return overflow;
    }

    return 0;
  }

  @override
  double recede(double dt) {
    assert(dt >= 0, 'Delta time cannot be negative.');
    _elapsed -= dt;

    if (_elapsed < 0) {
      final remaining = -_elapsed;
      _elapsed = 0;
      return remaining;
    }

    return 0;
  }

  @override
  void setToStart() => _elapsed = 0;

  @override
  void setToEnd() => _elapsed = duration;
}
