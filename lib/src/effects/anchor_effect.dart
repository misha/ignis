import 'package:ignis/src/anchor.dart';
import 'package:ignis/src/effects/controlled_effect.dart';
import 'package:ignis/src/nodes/transform_node.dart';

/// An effect that animates a [TransformNode]'s anchor over time.
abstract class AnchorEffect extends ControlledEffect {
  TransformNode? _target;

  /// The node whose anchor is mutated by this effect.
  TransformNode? get target => _target;

  /// Anchors [target] by [offset] relative to its anchor when the effect starts.
  ///
  /// If [target] is null, resolves to the closest [TransformNode].
  factory AnchorEffect.by({
    TransformNode? target,
    required Anchor offset,
    required EffectController controller,
    bool? cleanup,
  }) = _AnchorByEffect;

  /// Anchors [target] to [destination].
  ///
  /// If [target] is null, resolves to the closest [TransformNode].
  factory AnchorEffect.to({
    TransformNode? target,
    required Anchor destination,
    required EffectController controller,
    bool? cleanup,
  }) = _AnchorToEffect;

  AnchorEffect._({
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

class _AnchorByEffect extends AnchorEffect {
  final Anchor _offset;

  _AnchorByEffect({
    super.target,
    required Anchor offset,
    required super.controller,
    super.cleanup,
  }) : _offset = .new(offset.x, offset.y),
       super._() {
    onProgress((progress) {
      final anchor = _target!.anchor;
      final delta = progress - previousProgress;
      anchor.mutate().setValues(anchor.x + _offset.x * delta, anchor.y + _offset.y * delta);
    });
  }
}

class _AnchorToEffect extends AnchorEffect {
  final Anchor _destination;
  final Anchor _offset = .new(0, 0);

  _AnchorToEffect({
    super.target,
    required Anchor destination,
    required super.controller,
    super.cleanup,
  }) : _destination = .new(destination.x, destination.y),
       super._() {
    onStart(() {
      final anchor = _target!.anchor;
      _offset.mutate().setValues(_destination.x - anchor.x, _destination.y - anchor.y);
    });

    onProgress((progress) {
      final anchor = _target!.anchor;
      final delta = progress - previousProgress;
      anchor.mutate().setValues(anchor.x + _offset.x * delta, anchor.y + _offset.y * delta);
    });
  }
}
