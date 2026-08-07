import 'package:ignis/src/effects/controlled_effect.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/transform_node.dart';

/// A effect that animates a [TransformNode]'s position over time.
abstract class MoveEffect extends ControlledEffect {
  TransformNode? _target;

  /// The node whose position is mutated by this effect.
  TransformNode? get target => _target;

  /// Moves [target] by [offset] relative to its position when the effect starts.
  ///
  /// If [target] is null, resolves to the closest [TransformNode].
  factory MoveEffect.by({
    TransformNode? target,
    required Vector2 offset,
    required EffectController controller,
    bool? cleanup,
  }) = _MoveByEffect;

  /// Moves [target] to [destination].
  ///
  /// If [target] is null, resolves to the closest [TransformNode].
  factory MoveEffect.to({
    TransformNode? target,
    required Vector2 destination,
    required EffectController controller,
    bool? cleanup,
  }) = _MoveToEffect;

  MoveEffect._({
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

class _MoveByEffect extends MoveEffect {
  final Vector2 _offset;

  _MoveByEffect({
    super.target,
    required Vector2 offset,
    required super.controller,
    super.cleanup,
  }) : _offset = offset.clone(),
       super._() {
    onProgress((progress) {
      _target!.position.mutate().addScaled(_offset, progress - previousProgress);
    });
  }
}

class _MoveToEffect extends MoveEffect {
  final Vector2 _destination;
  final Vector2 _offset = .zero();

  _MoveToEffect({
    super.target,
    required Vector2 destination,
    required super.controller,
    super.cleanup,
  }) : _destination = destination.clone(),
       super._() {
    onStart(() {
      _offset.mutate()
        ..setFrom(_destination)
        ..subtract(_target!.position);
    });

    onProgress((progress) {
      _target!.position.mutate().addScaled(_offset, progress - previousProgress);
    });
  }
}
