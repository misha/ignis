import 'package:ignis/src/core.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/effect_node.dart';
import 'package:ignis/src/owners/position_owner.dart';
import 'package:ignis/src/owners/speed_owner.dart';

/// An effect that moves a [PositionOwner] by [velocity], every tick, forever.
class VelocityEffect extends EffectNode implements SpeedOwner {
  late final Target<PositionOwner> _target;

  /// The [PositionOwner] whose position is mutated by this effect.
  PositionOwner get target => _target.value;

  /// The rate of change of [target]'s position, in units per second.
  final MVector2 velocity;

  VelocityEffect({
    required this.velocity,
    super.enabled,
    super.priority,
  }) {
    _target = Target<PositionOwner>(this);
  }

  @override
  double get speed => velocity.length;

  @override
  set speed(double value) {
    if (velocity.normalize() == 0) return; // No direction to preserve.
    velocity.scale(value);
  }

  @override
  void build() {
    super.build();
    tick((dt) {
      target.position.addScaled(velocity, dt);
    });
  }

  @override
  void reset() {}
}
