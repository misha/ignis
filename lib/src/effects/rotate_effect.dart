import 'package:ignis/src/effect_controller.dart';
import 'package:ignis/src/effects/controlled_effect.dart';
import 'package:ignis/src/effects/effect_target.dart';
import 'package:ignis/src/effects/measurable_effect.dart';
import 'package:ignis/src/owners/angle_owner.dart';

/// An effect that animates an [AngleOwner]'s angle over time.
abstract class RotateEffect extends ControlledEffect implements MeasurableEffect {
  late final EffectTarget<AngleOwner> _target;

  /// The [AngleOwner] whose angle is mutated by this effect.
  AngleOwner? get target => _target.value;

  /// Rotates the closest [AngleOwner] ancestor by [angle], relative to its
  /// angle when the effect starts.
  factory RotateEffect.by({
    required double angle,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _RotateByEffect;

  /// Rotates the closest [AngleOwner] ancestor to [angle].
  factory RotateEffect.to({
    required double angle,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _RotateToEffect;

  RotateEffect._({
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    _target = EffectTarget<AngleOwner>(this);
  }
}

class _RotateByEffect extends RotateEffect {
  final double _angle;

  _RotateByEffect({
    required this._angle,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : super._() {
    onProgress((progress) {
      target!.angle += _angle * (progress - previousProgress);
    });
  }

  @override
  double measure() => _angle.abs();
}

class _RotateToEffect extends RotateEffect {
  final double _destination;
  double _offset = 0;

  _RotateToEffect({
    required double angle,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : _destination = angle,
       super._() {
    onMount(() {
      _offset = _destination - target!.angle;
    });

    onProgress((progress) {
      target!.angle += _offset * (progress - previousProgress);
    });
  }

  @override
  double measure() => _offset.abs();
}
