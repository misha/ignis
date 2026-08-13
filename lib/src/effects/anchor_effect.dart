import 'package:ignis/src/anchor.dart';
import 'package:ignis/src/effect_controller.dart';
import 'package:ignis/src/effects/controlled_effect.dart';
import 'package:ignis/src/effects/effect_target.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/owners/anchor_owner.dart';

/// An effect that animates an [AnchorOwner]'s anchor over time.
abstract class AnchorEffect extends ControlledEffect {
  late final EffectTarget<AnchorOwner> _target;

  /// The [AnchorOwner] whose anchor is mutated by this effect.
  AnchorOwner? get target => _target.value;

  /// Anchors the closest [AnchorOwner] ancestor by [offset], relative to its
  /// anchor when the effect is mounted.
  factory AnchorEffect.by({
    required Anchor offset,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _AnchorByEffect;

  /// Anchors the closest [AnchorOwner] ancestor to [destination].
  factory AnchorEffect.to({
    required Anchor destination,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _AnchorToEffect;

  AnchorEffect._({
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    _target = EffectTarget<AnchorOwner>(this);
  }
}

class _AnchorByEffect extends AnchorEffect {
  final Vector2 _offset;

  _AnchorByEffect({
    required Anchor offset,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : _offset = offset.clone(),
       super._() {
    onProgress((progress) {
      target!.anchor.mutate().addScaled(_offset, progress - previousProgress);
    });
  }
}

class _AnchorToEffect extends AnchorEffect {
  final Vector2 _destination;
  final Vector2 _offset = .zero();

  _AnchorToEffect({
    required Anchor destination,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : _destination = destination.clone(),
       super._() {
    onMount(() {
      _offset.mutate()
        ..setFrom(_destination)
        ..subtract(target!.anchor);
    });

    onProgress((progress) {
      target!.anchor.mutate().addScaled(_offset, progress - previousProgress);
    });
  }
}
