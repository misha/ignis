// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';

/// A [Node] with a concept of being finished. Also called `effect`.
///
/// It reports this via [onFinish], while [reset] can be used to run it again.
///
/// Effects are nodes. They must be added to the tree in order to function.
abstract class EffectNode extends Node {
  /// Emitted once, when this effect finishes progressing.
  final onFinish = Signal0();

  /// Whether to [detach] once finished. Defaults to false.
  bool cleanup;

  /// Resets this effect back to its start.
  void reset();

  EffectNode({
    bool? cleanup,
    super.enabled,
    super.priority,
    super.children,
  }) : cleanup = cleanup ?? false;

  @override
  void build() {
    super.build();
    onFinish(() {
      if (cleanup) detach();
    });
  }
}
