// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/message.dart';

/// A [Node] with a concept of being finished. Also called `effect`.
///
/// It reports this via [EffectFinish], while [reset] can be used to run it again.
///
/// Effects are nodes. They must be added to the tree in order to function.
abstract class EffectNode extends Node {
  /// Whether to [detach] once finished. Defaults to false.
  bool cleanup;

  EffectNode({
    bool? cleanup,
    super.enabled,
    super.priority,
    super.children,
  }) : cleanup = cleanup ?? false;

  /// Resets this effect back to its start.
  void reset();

  /// Emits [EffectFinish], then [detach]es if [cleanup] is set.
  @protected
  void finish() {
    parent?.post(EffectFinish(this));
    if (cleanup) detach();
  }
}

/// Emitted once, when [effect] finishes progressing.
final class EffectFinish extends Message {
  final EffectNode effect;

  const EffectFinish(this.effect);
}
