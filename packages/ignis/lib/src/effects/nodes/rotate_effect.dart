// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
import 'package:ignis/src/effects/interfaces/measurable_effect.dart';
import 'package:ignis/src/effects/nodes/timeline_effect.dart';
import 'package:ignis/src/owners/angle_owner.dart';
import 'package:ignis/src/timeline.dart';

/// An effect that animates an [AngleOwner]'s angle over time.
abstract class RotateEffect extends TimelineEffect implements MeasurableEffect {
  late final Target<AngleOwner> _target;

  /// The [AngleOwner] whose angle is mutated by this effect.
  AngleOwner get target => _target.value;

  /// Rotates the closest [AngleOwner] ancestor by [angle], relative to its
  /// angle when the effect starts.
  factory RotateEffect.by({
    required double angle,
    required Timeline timeline,
    bool? cleanup,
    bool? enabled,
  }) = _RotateByEffect;

  /// Rotates the closest [AngleOwner] ancestor to [angle].
  factory RotateEffect.to({
    required double angle,
    required Timeline timeline,
    bool? cleanup,
    bool? enabled,
  }) = _RotateToEffect;

  RotateEffect._({
    required super.timeline,
    super.cleanup,
    super.enabled,
  }) {
    _target = Target<AngleOwner>(this);
  }
}

class _RotateByEffect extends RotateEffect {
  final double _angle;

  _RotateByEffect({
    required this._angle,
    required super.timeline,
    super.cleanup,
    super.enabled,
  }) : super._();

  @override
  void build() {
    super.build();

    onProgress((progress) {
      target.angle += _angle * (progress - previousProgress);
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
    required super.timeline,
    super.cleanup,
    super.enabled,
  }) : _destination = angle,
       super._();

  @override
  void build() {
    super.build();
    _offset = _destination - target.angle;

    onProgress((progress) {
      target.angle += _offset * (progress - previousProgress);
    });
  }

  @override
  double measure() => _offset.abs();
}
