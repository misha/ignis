import 'package:ignis/src/nodes/effect_node.dart';
import 'package:ignis/src/nodes/transform_node.dart';

/// An [EffectNode] that animates a [TransformNode]'s angle over time.
abstract class RotateEffect extends EffectNode {
  TransformNode? _target;

  /// The node whose angle is mutated by this effect.
  TransformNode? get target => _target;

  /// Rotates [target] by [angle], relative to its angle when the effect starts.
  ///
  /// If [target] is null, resolves to the closest [TransformNode].
  factory RotateEffect.by({
    TransformNode? target,
    required double angle,
    required EffectController controller,
    bool? cleanup,
  }) = _RotateByEffect;

  /// Rotates [target] to [angle].
  ///
  /// If [target] is null, resolves to the closest [TransformNode].
  factory RotateEffect.to({
    TransformNode? target,
    required double angle,
    required EffectController controller,
    bool? cleanup,
  }) = _RotateToEffect;

  RotateEffect._({
    this._target,
    required super.controller,
    super.cleanup,
  }) {
    if (_target == null) {
      onMount(() {
        _target = ancestors.whereType<TransformNode>().firstOrNull;
        assert(_target != null, 'Target must be set, or have a TransformNode ancestor.');
      });

      onUnmount(() {
        _target = null;
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
      _target!.angle += _angle * (progress - previousProgress);
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
      _offset = _destination - _target!.angle;
    });

    onProgress((progress) {
      _target!.angle += _offset * (progress - previousProgress);
    });
  }
}
