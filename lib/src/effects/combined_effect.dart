import 'package:ignis/src/nodes/effect_node.dart';

/// A node that runs [effects] together, exposing [onFinish] once every one
/// of them has finished.
class CombinedEffect extends EffectNode {
  /// The effects run together.
  final List<EffectNode> effects;

  int _remaining;

  CombinedEffect({
    required this.effects,
    super.cleanup,
    super.enabled,
    super.priority,
  }) : assert(effects.isNotEmpty, 'At least 1 effect is required.'),
       _remaining = effects.length,
       super(children: effects) {
    for (final effect in effects) {
      effect.onFinish(_track);
    }
  }

  @override
  void reset() {
    _remaining = effects.length;

    for (final effect in effects) {
      effect.reset();
    }
  }

  void _track() {
    _remaining -= 1;

    if (_remaining == 0) {
      onFinish.emit();
    }
  }
}
