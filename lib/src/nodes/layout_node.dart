import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:ignis/src/debug.dart';
import 'package:ignis/src/layout_constraints.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/sized_node.dart';

/// A [SizedNode] whose size is computed via constraint propagation, rather
/// than being intrinsic to its content.
///
/// A [LayoutNode] with no [LayoutNode] ancestor is a layout root: it lays
/// itself out from [tick], every frame, against the scene's size. A
/// [LayoutNode] with a [LayoutNode] ancestor is laid out by that ancestor
/// instead, via a direct [layout] call inside the ancestor's [constrain].
///
/// Only reaches [LayoutNode] descendants connected through a chain of
/// direct [SizedNode] children - one behind a plain, non-[SizedNode] node is
/// invisible to its ancestor's [constrain] and is never laid out. Keep
/// layout subtrees contiguous.
/// TODO: Is this actually an acceptable restriction?
abstract class LayoutNode extends SizedNode {
  @override
  final Vector2 size = .zero();

  LayoutNode({
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  });

  /// Lays out this node under [constraints] and stores the result.
  @nonVirtual
  void layout(LayoutConstraints constraints) {
    size.mutate().setFrom(constraints.satisfy(constrain(constraints)));
  }

  /// Lays this node out under [constraints], then returns its resulting size.
  @override
  Vector2 measure(LayoutConstraints constraints) {
    layout(constraints);
    return size;
  }

  /// Computes and returns this node's size under [constraints], laying out
  /// and positioning every [SizedNode] child that participates in layout.
  ///
  /// The returned size need not satisfy [constraints]; [layout] clamps it.
  @visibleForOverriding
  Vector2 constrain(LayoutConstraints constraints);

  /// A [LayoutNode] can always be resized by an ancestor `FlexNode`.
  @override
  bool get canResize => true;

  @nonVirtual
  @override
  void tick(double dt) {
    // TODO: Expensive! Perhaps ancestors can mark layout children instead.
    if (ancestors.whereType<LayoutNode>().isNotEmpty) return;
    layout(_rootConstraints());
  }

  LayoutConstraints _rootConstraints() {
    if (!isMounted || !scene.hasSize) return .unbounded();
    return .tight(scene.size);
  }

  @override
  void debugRenderAnchored(Canvas canvas) {
    canvas.drawRect(.fromLTWH(0, 0, width, height), DEBUG_LAYOUT_PAINT);
  }
}
