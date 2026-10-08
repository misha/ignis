// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
import 'package:ignis/src/message.dart';
import 'package:ignis/src/nodes/effect_node.dart';

/// A node that chains [effects] one after another.
///
/// Every effect is a child for the sequence's whole life, but only the current
/// one is enabled.
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
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        for (final effect in effects) {
          add(effect..disable());
        }

      case Update():
        if (_current < effects.length) effects[_current].enable();

      case EffectFinish(:final effect):
        if (_current >= effects.length) break;
        if (!identical(effect, effects[_current])) break;
        effect.disable();
        _current += 1;
        if (_current >= effects.length) finish();
    }
  }

  @override
  void reset() {
    if (_current < effects.length) effects[_current].disable();

    for (final effect in effects) {
      effect.reset();
    }

    _current = 0;
  }
}
