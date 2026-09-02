// SPDX-AI-Disclosure: ai-generated

import 'package:flutter/foundation.dart';
import 'package:ignis/src/nodes/opacity_node.dart';
import 'package:ignis/src/nodes/transition_node.dart';

/// One of the subtrees a [TransitionNode] swaps between, a direct child of it
/// named for [TransitionNode.show].
///
/// Its transform, opacity, enablement, and priority belong to the host: a
/// transition writes the pose mid-flight, and settling returns it to [reset].
class TransitionGroupNode<T> extends OpacityNode {
  /// The name [TransitionNode.show] swaps to.
  final T name;

  TransitionGroupNode({
    required this.name,
    super.children,
  });

  @override
  void build() {
    super.build();
    final host = parent;

    // TODO: Maybe needs a `strict` parameter.
    if (host is! TransitionNode<T>) {
      throw StateError('TransitionGroupNode must be a direct child of a TransitionNode<$T>.');
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
