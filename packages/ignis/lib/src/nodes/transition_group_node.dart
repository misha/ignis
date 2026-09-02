// SPDX-AI-Disclosure: ai-generated

import 'package:flutter/foundation.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/nodes/opacity_node.dart';
import 'package:ignis/src/nodes/transition_node.dart';

/// One of the subtrees a [TransitionNode] swaps between, registered under
/// [name] with the closest one above it.
///
/// Its transform and opacity belong to the swap: a transition writes them
/// mid-flight, and settling returns them to [reset].
class TransitionGroupNode<T> extends OpacityNode {
  /// The name this group registers under.
  final T name;

  late final _target = Target<TransitionNode<T>?>(this);

  TransitionGroupNode({
    required this.name,
    super.enabled,
    super.priority,
    super.children,
  });

  @override
  void build() {
    super.build();
    final host = _target.value;

    // TODO: Maybe needs a `strict` parameter.
    if (host == null) {
      throw StateError('TransitionGroupNode requires a TransitionNode<$T> ancestor.');
    }

    host.register(this);
    trash(() => host.unregister(this));
  }

  /// Returns this group to how it stands outside a swap.
  @internal
  void reset() {
    position.setZero();
    scale.splat(1);
    angle = 0;
    opacity = 1;
  }
}
