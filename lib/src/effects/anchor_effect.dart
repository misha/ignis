import 'package:ignis/src/anchor.dart';
import 'package:ignis/src/effect_controller.dart';
import 'package:ignis/src/effects/controlled_effect.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/sized_node.dart';

/// An effect that animates a [SizedNode]'s anchor over time.
abstract class AnchorEffect<C extends BaseEffectController> extends ControlledEffect<C> {
  SizedNode? _target;

  /// The node whose anchor is mutated by this effect.
  SizedNode? get target => _target;

  /// Anchors [target] by [offset] relative to its anchor when the effect starts.
  ///
  /// If [target] is null, resolves to the closest [SizedNode].
  factory AnchorEffect.by({
    SizedNode? target,
    required Anchor offset,
    required C controller,
    bool? cleanup,
    bool? enabled,
  }) = _AnchorByEffect<C>;

  /// Anchors [target] to [destination].
  ///
  /// If [target] is null, resolves to the closest [SizedNode].
  factory AnchorEffect.to({
    SizedNode? target,
    required Anchor destination,
    required C controller,
    bool? cleanup,
    bool? enabled,
  }) = _AnchorToEffect<C>;

  AnchorEffect._({
    this._target,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    if (_target == null) {
      onMount(() {
        _target = ancestors.whereType<SizedNode>().firstOrNull;
        assert(_target != null, 'Target must be set, or have a SizedNode ancestor.');
      });

      onUnmount(() {
        _target = null;
      });
    }
  }
}

class _AnchorByEffect<C extends BaseEffectController> extends AnchorEffect<C> {
  final Vector2 _offset;

  _AnchorByEffect({
    super.target,
    required Anchor offset,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : _offset = offset.clone(),
       super._() {
    onProgress((progress) {
      _target!.anchor.mutate().addScaled(_offset, progress - previousProgress);
    });
  }
}

class _AnchorToEffect<C extends BaseEffectController> extends AnchorEffect<C> {
  final Vector2 _destination;
  final Vector2 _offset = .zero();

  _AnchorToEffect({
    super.target,
    required Anchor destination,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : _destination = destination.clone(),
       super._() {
    onStart(() {
      _offset.mutate()
        ..setFrom(_destination)
        ..subtract(_target!.anchor);
    });

    onProgress((progress) {
      _target!.anchor.mutate().addScaled(_offset, progress - previousProgress);
    });
  }
}
