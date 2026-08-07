import 'package:ignis/src/nodes/effect_node.dart';

/// A node that chains [effects] one after another, adding the next only
/// once the previous one finishes.
class SequentialEffect extends EffectNode {
  /// The effects run in sequence.
  final List<EffectNode> effects;

  /// Whether to [detach] once the last effect finishes. Defaults to false.
  bool cleanup;

  int _current = 0;

  SequentialEffect({
    required this.effects,
    bool? cleanup,
    super.enabled,
    super.priority,
  }) : assert(effects.isNotEmpty, 'At least 1 effect is required.'),
       cleanup = cleanup ?? false {
    for (var i = 0; i < effects.length; i += 1) {
      effects[i].onFinish(() => _track(i));
    }

    _advance();
  }

  @override
  void reset() {
    if (_current < effects.length && _current != 0) {
      effects[_current].detach();
    }

    for (final effect in effects) {
      effect.reset();
    }

    _current = 0;
    _advance();
  }

  void _advance() {
    if (_current >= effects.length) {
      onFinish.emit();
      if (cleanup) detach();
      return;
    }

    add(effects[_current]);
  }

  void _track(int index) {
    if (index == _current) {
      effects[_current].detach();
      _current += 1;
      _advance();
    }
  }
}
