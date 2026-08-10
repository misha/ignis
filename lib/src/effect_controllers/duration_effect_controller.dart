import 'package:flutter/foundation.dart';
import 'package:ignis/src/effect_controller.dart';

/// Base for [EffectController]s driven by a fixed [duration], counting
/// [elapsed] time from 0 up to [duration].
abstract class DurationEffectController extends EffectController {
  /// How long this controller takes to complete.
  @override
  final double duration;

  double _elapsed;

  DurationEffectController(this.duration)
    : assert(duration >= 0, 'Duration cannot be negative.'),
      _elapsed = 0,
      super.empty();

  /// This controller's elapsed time, from 0 to [duration].
  @protected
  double get elapsed => _elapsed;

  @override
  bool get hasStarted => true;

  @override
  bool get isFinished => _elapsed == duration;

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
