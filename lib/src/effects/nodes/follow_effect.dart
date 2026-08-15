import 'package:ignis/src/effects/effect_target.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/effect_node.dart';
import 'package:ignis/src/owners/position_owner.dart';

/// An effect that moves a [PositionOwner] toward [following] at [speed].
///
/// Emits [EffectNode.onFinish] on arrival, and again each time it falls
/// behind and catches back up.
class FollowEffect extends EffectNode {
  late final EffectTarget<PositionOwner> _target;

  /// The [PositionOwner] whose position is mutated by this effect.
  PositionOwner? get target => _target.value;

  /// Where [target] moves toward.
  final PositionOwner following;

  /// Where [target] is currently moving toward.
  Vector2 get destination => following.position;

  /// How fast [target] closes the distance to [following].
  double speed;

  bool _arrived = false;

  FollowEffect({
    required this.following,
    required this.speed,
    super.cleanup,
    super.enabled,
    super.priority,
  }) {
    _target = EffectTarget<PositionOwner>(this);
  }

  @override
  void tick(double dt) {
    final position = target!.position;
    final offset = destination - position;
    final distance = offset.length;
    final step = speed * dt;

    if (distance <= step) {
      position.setFrom(destination);

      if (!_arrived) {
        _arrived = true;
        onFinish.emit();
      }
    } else {
      position.addScaled(offset, step / distance);
      _arrived = false;
    }
  }

  @override
  void reset() {
    _arrived = false;
  }
}
