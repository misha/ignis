import 'package:ignis/src/effects/effect_target.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/effect_node.dart';
import 'package:ignis/src/owners/position_owner.dart';
import 'package:ignis/src/owners/speed_owner.dart';

/// An effect that moves a [PositionOwner] by [velocity], every tick, forever.
class VelocityEffect extends EffectNode implements SpeedOwner {
  late final EffectTarget<PositionOwner> _target;

  /// The [PositionOwner] whose position is mutated by this effect.
  PositionOwner? get target => _target.value;

  /// The rate of change of [target]'s position, in units per second.
  final Vector2 velocity;

  VelocityEffect({
    required this.velocity,
    super.enabled,
    super.priority,
  }) {
    _target = EffectTarget<PositionOwner>(this);
  }

  @override
  double get speed => velocity.length;

  @override
  set speed(double value) {
    if (velocity.mutate().normalize() == 0) return; // No direction to preserve.
    velocity.mutate().scale(value);
  }

  @override
  void tick(double dt) {
    target!.position.mutate().addScaled(velocity, dt);
  }

  @override
  void reset() {
    // Nothing to do.
  }
}
