import 'package:ignis/src/node.dart';
import 'package:ignis/src/signal.dart';

/// A [Node] with a concept of being finished.
///
/// It reports this via [onFinish], while [reset] can be used to run it again.
///
/// Effects are nodes. They must be added to the tree in order to function.
abstract class EffectNode extends Node {
  /// Emitted once this effect finishes.
  final onFinish = Signal0();

  /// Resets this effect back to its start.
  void reset();

  EffectNode({
    super.enabled,
    super.priority,
    super.children,
  });
}
