// SPDX-AI-Disclosure: none

import 'package:ignis/src/nodes/effect_node.dart';

/// A node that chains [effects] one after another.
class SequentialEffect extends EffectNode {
  /// The effects run in sequence.
  final List<EffectNode> effects;

  int _current = 0;

  SequentialEffect({
    required this.effects,
    super.cleanup,
    super.enabled,
    super.priority,
  }) : assert(effects.isNotEmpty, 'At least 1 effect is required.');

  @override
  void build() {
    super.build();

    for (var index = 0; index < effects.length; index += 1) {
      effects[index].onFinish(() {
        if (index == _current) {
          effects[_current].detach();
          _current += 1;
          _advance();
        }
      });
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
      return;
    }

    add(effects[_current]);
  }
}
