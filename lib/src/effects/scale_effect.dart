import 'package:ignis/src/effect_controller.dart';
import 'package:ignis/src/effects/controlled_effect.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/transform_node.dart';

/// An effect that animates a [TransformNode]'s scale over time.
abstract class ScaleEffect extends ControlledEffect {
  TransformNode? _target;

  /// The node whose scale is mutated by this effect.
  TransformNode? get target => _target;

  /// Scales [target] by [offset] relative to its scale when the effect starts.
  ///
  /// If [target] is null, resolves to the closest [TransformNode].
  factory ScaleEffect.by({
    TransformNode? target,
    required Vector2 offset,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _ScaleByEffect;

  /// Scales [target] to [destination].
  ///
  /// If [target] is null, resolves to the closest [TransformNode].
  factory ScaleEffect.to({
    TransformNode? target,
    required Vector2 destination,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _ScaleToEffect;

  ScaleEffect._({
    this._target,
    required super.controller,
    super.cleanup,
    super.enabled,
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

class _ScaleByEffect extends ScaleEffect {
  final Vector2 _offset;

  _ScaleByEffect({
    super.target,
    required Vector2 offset,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : _offset = offset.clone(),
       super._() {
    onProgress((progress) {
      _target!.scale.mutate().addScaled(_offset, progress - previousProgress);
    });
  }
}

class _ScaleToEffect extends ScaleEffect {
  final Vector2 _destination;
  final Vector2 _offset = .zero();

  _ScaleToEffect({
    super.target,
    required Vector2 destination,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : _destination = destination.clone(),
       super._() {
    onMount(() {
      _offset.mutate()
        ..setFrom(_destination)
        ..subtract(_target!.scale);
    });

    onProgress((progress) {
      _target!.scale.mutate().addScaled(_offset, progress - previousProgress);
    });
  }
}
