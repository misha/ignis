import 'package:flutter/animation.dart';
import 'package:ignis/src/effect_controller.dart';
import 'package:ignis/src/effect_controllers/duration_effect_controller.dart';
import 'package:ignis/src/effect_controllers/terminal_effect_controller.dart';
import 'package:ignis/src/effects/controlled_effect.dart';
import 'package:ignis/src/effects/measurable_effect.dart';

class SpeedEffectController extends EffectController {
  /// How fast to progress, in measured units per second.
  final double speed;

  /// Shapes progress over time. Defaults to [Curves.linear].
  final Curve curve;

  MeasurableEffect? _effect;
  EffectController? _child;

  SpeedEffectController(this.speed, [Curve? curve])
    : assert(speed > 0, 'Speed must be positive.'),
      curve = curve ?? Curves.linear,
      super.empty();

  @override
  void attach(ControlledEffect effect) {
    assert(
      effect is MeasurableEffect,
      'SpeedEffectController requires a MeasurableEffect.',
    );

    _effect = effect as MeasurableEffect;
  }

  EffectController _resolve() {
    final effect = _effect;

    if (effect == null) {
      throw StateError('SpeedEffectController must be attached to an effect before use.');
    }

    final distance = effect.measure();

    if (distance > 0) {
      return DurationEffectController(distance / speed, curve);
    } else {
      // A zero distance can't drive a curve; treat it as already finished.
      return const TerminalEffectController();
    }
  }

  @override
  double? get duration => _child?.duration;

  @override
  bool get hasStarted => _child?.hasStarted ?? false;

  @override
  bool get isFinished => _child?.isFinished ?? false;

  @override
  double get progress => _child?.progress ?? 0;

  @override
  double advance(double dt) => (_child ??= _resolve()).advance(dt);

  @override
  double recede(double dt) => (_child ??= _resolve()).recede(dt);

  @override
  void setToStart() => _child?.setToStart();

  @override
  void setToEnd() => (_child ??= _resolve()).setToEnd();
}
