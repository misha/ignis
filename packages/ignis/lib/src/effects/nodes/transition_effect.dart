// SPDX-AI-Disclosure: ai-generated

import 'package:flutter/foundation.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/effects/nodes/controlled_effect.dart';
import 'package:ignis/src/nodes/spatial_node.dart';

/// Animates the transition between two nodes, [from] and [to].
abstract class TransitionEffect extends ControlledEffect {
  /// The side on its way in: concealed until the swap, and adopted beside
  /// this transition when nothing else added it.
  final SpatialNode to;

  /// The side on its way out, or null when there is nothing to leave.
  final SpatialNode? from;

  /// The progress at which the sides trade places.
  ///
  /// Defaults to 0.5. When 0, both sides are visible from the first frame.
  double get swapAt => 0.5;

  /// Emitted once, when the sides trade places.
  final onSwap = Signal0();

  bool _swapped = false;

  /// Whether the sides have traded places.
  bool get isSwapped => _swapped;

  TransitionEffect(
    this.to,
    this.from, {
    required super.controller,
    super.cleanup,
    super.enabled,
    super.priority,
  }) : assert(
         !identical(from, to),
         "'to' and 'from' must be different nodes.",
       );

  @override
  void build() {
    super.build();
    if (to.parent == null) parent!.add(to);
    if (!_swapped) to.disable();

    onProgress((progress) {
      if (!_swapped && progress >= swapAt) _swap();
      apply(progress);
    });

    onFinish(() {
      if (!_swapped) _swap();
      _restore(to);
      final from = this.from;
      if (from == null) return;
      _restore(from);
    });
  }

  @override
  void reset() {
    super.reset();
    _swapped = false;
  }

  /// Applies [progress] each frame: move the handles, fade the layers,
  /// update the paints declared in [build].
  @visibleForOverriding
  void apply(double progress);

  void _swap() {
    _swapped = true;
    to.enable();
    onSwap.emit();
  }

  // TODO: This is obviously wrong.
  static void _restore(SpatialNode handle) {
    handle.position.setZero();
    handle.scale.setValues(1, 1);
    handle.angle = 0;
    handle.opacity = 1;
  }
}
