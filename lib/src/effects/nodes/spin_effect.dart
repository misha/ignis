import 'package:ignis/src/effects/effect_target.dart';
import 'package:ignis/src/nodes/effect_node.dart';
import 'package:ignis/src/owners/angle_owner.dart';
import 'package:ignis/src/owners/speed_owner.dart';

/// An effect that spins an [AngleOwner] by [speed], every tick, forever.
class SpinEffect extends EffectNode implements SpeedOwner {
  late final EffectTarget<AngleOwner> _target;

  /// The [AngleOwner] whose angle is mutated by this effect.
  AngleOwner? get target => _target.value;

  /// The rate of change of [target]'s angle, in radians per second.
  @override
  double speed;

  SpinEffect({
    required this.speed,
    super.enabled,
    super.priority,
  }) {
    _target = EffectTarget<AngleOwner>(this);
  }

  @override
  void build() {
    super.build();
    _target.resolve();

    onUpdate((dt) {
      target!.angle += speed * dt;
    });
  }

  @override
  void reset() {}
}
