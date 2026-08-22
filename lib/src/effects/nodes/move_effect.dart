// SPDX-AI-Disclosure: none

import 'package:ignis/src/effects/effect_controller.dart';
import 'package:ignis/src/effects/interfaces/measurable_effect.dart';
import 'package:ignis/src/effects/nodes/controlled_effect.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/owners/position_owner.dart';
import 'package:ignis/src/target.dart';

/// An effect that animates a [PositionOwner]'s position over time.
abstract class MoveEffect extends ControlledEffect implements MeasurableEffect {
  late final Target<PositionOwner> _target;

  /// The [PositionOwner] whose position is mutated by this effect.
  PositionOwner? get target => _target.value;

  /// Moves the closest [PositionOwner] ancestor by [offset], relative to its
  /// position when the effect is mounted.
  factory MoveEffect.by({
    required Vector2 offset,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _MoveByEffect;

  /// Moves the closest [PositionOwner] ancestor to [destination].
  factory MoveEffect.to({
    required Vector2 destination,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _MoveToEffect;

  MoveEffect._({
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    _target = Target<PositionOwner>(this);
  }

  @override
  void build() {
    super.build();
    _target.resolve();
  }
}

class _MoveByEffect extends MoveEffect {
  final Vector2 _offset;

  _MoveByEffect({
    required Vector2 offset,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : _offset = offset.clone(),
       super._();

  @override
  void build() {
    super.build();

    onProgress((progress) {
      target!.position.addScaled(_offset, progress - previousProgress);
    });
  }

  @override
  double measure() => _offset.length;
}

class _MoveToEffect extends MoveEffect {
  final Vector2 _destination;
  final MVector2 _offset = .zero();

  _MoveToEffect({
    required Vector2 destination,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : _destination = destination.clone(),
       super._();

  @override
  void build() {
    super.build();

    _offset
      ..setFrom(_destination)
      ..subtract(target!.position);

    onProgress((progress) {
      target!.position.addScaled(_offset, progress - previousProgress);
    });
  }

  @override
  double measure() => _offset.length;
}
