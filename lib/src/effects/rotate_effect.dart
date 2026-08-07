import 'package:ignis/src/nodes/effect_node.dart';
import 'package:ignis/src/nodes/transform_node.dart';

/// An [EffectNode] that animates a [TransformNode]'s angle over time.
abstract class RotateEffect extends EffectNode {
  /// The node whose angle is mutated as this effect progresses.
  ///
  /// If left null, resolves to the closest [TransformNode] ancestor on
  /// mount, and clears again on unmount.
  TransformNode? target;

  /// Rotates [target] by [angle], relative to its angle when the effect starts.
  factory RotateEffect.by({
    TransformNode? target,
    required double angle,
    required EffectController controller,
    bool? cleanup,
  }) = _RotateByEffect;

  /// Rotates [target] to [angle].
  factory RotateEffect.to({
    TransformNode? target,
    required double angle,
    required EffectController controller,
    bool? cleanup,
  }) = _RotateToEffect;

  RotateEffect._({
    this.target,
    required super.controller,
    super.cleanup,
  }) {
    if (target == null) {
      onMount(() {
        target = ancestors.whereType<TransformNode>().firstOrNull;
        assert(target != null, 'RotateEffect requires a TransformNode target or ancestor.');
      });

      onUnmount(() {
        target = null;
      });
    }
  }
}

class _RotateByEffect extends RotateEffect {
  final double _angle;

  _RotateByEffect({
    super.target,
    required this._angle,
    required super.controller,
    super.cleanup,
  }) : super._() {
    onProgress((progress) {
      target!.angle += _angle * (progress - previousProgress);
    });
  }
}

class _RotateToEffect extends RotateEffect {
  final double _destination;
  double _offset = 0;

  _RotateToEffect({
    super.target,
    required double angle,
    required super.controller,
    super.cleanup,
  }) : _destination = angle,
       super._() {
    onStart(() {
      _offset = _destination - target!.angle;
    });

    onProgress((progress) {
      target!.angle += _offset * (progress - previousProgress);
    });
  }
}
