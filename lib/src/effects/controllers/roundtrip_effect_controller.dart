import 'dart:math' as math;

import 'package:ignis/src/effects/effect_controller.dart';
import 'package:ignis/src/effects/nodes/controlled_effect.dart';

/// Plays [child] forward, then back down to its start, using it as a single
/// shared instance for both legs.
class RoundtripEffectController extends EffectController {
  /// The controller played there and back.
  final EffectController child;

  final double _legDuration;
  double _legElapsed = 0;
  bool _reversed = false;
  bool _finished = false;

  RoundtripEffectController(this.child)
    : assert(
        child.duration?.isFinite ?? false,
        'Cannot round-trip a controller with an unknown or infinite duration.',
      ),
      _legDuration = child.duration!,
      super.empty();

  @override
  void attach(ControlledEffect effect) => child.attach(effect);

  @override
  double? get duration => _legDuration * 2;

  @override
  bool get hasStarted => true;

  @override
  bool get isFinished => _finished;

  @override
  double get progress => child.progress;

  @override
  double advance(double dt) {
    assert(dt >= 0, 'Delta time cannot be negative.');
    var remaining = dt;

    if (!_reversed) {
      final step = math.min(remaining, _legDuration - _legElapsed);
      child.advance(step);
      _legElapsed += step;
      remaining -= step;

      if (_legElapsed < _legDuration) return 0;

      _reversed = true;
      _legElapsed = 0;
    }

    final step = math.min(remaining, _legDuration - _legElapsed);
    child.recede(step);
    _legElapsed += step;
    remaining -= step;

    if (_legElapsed >= _legDuration) _finished = true;

    return remaining;
  }

  @override
  double recede(double dt) {
    assert(dt >= 0, 'Delta time cannot be negative.');
    var remaining = dt;
    _finished = false;

    if (_reversed) {
      final step = math.min(remaining, _legElapsed);
      child.advance(step);
      _legElapsed -= step;
      remaining -= step;

      if (_legElapsed > 0) return remaining;

      _reversed = false;
      _legElapsed = _legDuration;
    }

    final step = math.min(remaining, _legElapsed);
    child.recede(step);
    _legElapsed -= step;
    remaining -= step;

    return remaining;
  }

  @override
  void setToStart() {
    child.setToStart();
    _legElapsed = 0;
    _reversed = false;
    _finished = false;
  }

  @override
  void setToEnd() {
    child.setToStart();
    _legElapsed = _legDuration;
    _reversed = true;
    _finished = true;
  }
}
