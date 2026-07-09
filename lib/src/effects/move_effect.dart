import 'package:ignis/src/nodes/effect_node.dart';
import 'package:ignis/src/math.dart';

/// An [EffectNode] that animates a [Vector2] position over time.
abstract class MoveEffect extends EffectNode {
  /// The position mutated as this effect progresses.
  final Vector2 position;

  /// Moves [position] by [offset], relative to its position when the effect starts.
  factory MoveEffect.by({
    required Vector2 offset,
    required Vector2 position,
    required EffectController controller,
  }) = _MoveByEffect;

  /// Moves [position] to [destination].
  factory MoveEffect.to({
    required Vector2 destination,
    required Vector2 position,
    required EffectController controller,
  }) = _MoveToEffect;

  MoveEffect._({
    required this.position,
    required super.controller,
  });
}

class _MoveByEffect extends MoveEffect {
  final Vector2 _offset;

  _MoveByEffect({
    required Vector2 offset,
    required super.position,
    required super.controller,
  }) : _offset = offset.clone(),
       super._() {
    onProgress((progress) {
      position.mutate().addScaled(_offset, progress - previousProgress);
    });
  }
}

class _MoveToEffect extends MoveEffect {
  final Vector2 _destination;
  final Vector2 _offset = .zero();

  _MoveToEffect({
    required Vector2 destination,
    required super.position,
    required super.controller,
  }) : _destination = destination.clone(),
       super._() {
    onStart(() {
      _offset.mutate()
        ..setFrom(_destination)
        ..subtract(position);
    });

    onProgress((progress) {
      position.mutate().addScaled(_offset, progress - previousProgress);
    });
  }
}
