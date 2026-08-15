import 'package:ignis/src/effects/effect_controller.dart';
import 'package:ignis/src/effects/nodes/controlled_effect.dart';

/// Runs [child] [times] times before finishing, restarting it from the
/// beginning after each completed run.
class RepeatEffectController extends EffectController {
  /// The controller run repeatedly.
  final EffectController child;

  /// How many times to run [child] before finishing.
  final int times;

  int _remaining;

  RepeatEffectController(this.child, this.times)
    : assert(times > 0, 'Times must be positive.'),
      assert(!child.isInfinite, 'Cannot repeat an infinite controller.'),
      _remaining = times,
      super.empty();

  @override
  void attach(ControlledEffect effect) => child.attach(effect);

  @override
  double? get duration {
    final childDuration = child.duration;
    return childDuration == null ? null : childDuration * times;
  }

  @override
  bool get hasStarted => child.hasStarted;

  @override
  bool get isFinished => _remaining == 0;

  @override
  double get progress => child.progress;

  @override
  double advance(double dt) {
    var overflow = child.advance(dt);

    while (overflow > 0 && _remaining > 0) {
      _remaining -= 1;

      if (_remaining != 0) {
        child.setToStart();
        overflow = child.advance(overflow);
      }
    }

    if (_remaining == 1 && child.isFinished) _remaining -= 1;
    return overflow;
  }

  @override
  double recede(double dt) {
    var remaining = child.recede(dt);

    while (remaining > 0 && _remaining < times) {
      _remaining += 1;
      child.setToEnd();
      remaining = child.recede(remaining);
    }

    return remaining;
  }

  @override
  void setToStart() {
    child.setToStart();
    _remaining = times;
  }

  @override
  void setToEnd() {
    child.setToEnd();
    _remaining = 0;
  }
}
