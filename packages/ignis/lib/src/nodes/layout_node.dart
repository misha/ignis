// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/layout/layout_constraints.dart';
import 'package:ignis/src/layout/layout_flex.dart';
import 'package:ignis/src/layout/layout_item.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/shape.dart';

/// A [SpatialNode] whose size is computed via constraint propagation, rather
/// than being intrinsic to its content.
///
/// A [LayoutNode] whose parent is a [LayoutNode] is laid out by that parent,
/// via a direct [layout] call inside its [constrain]. Any other one is a
/// layout root: it lays itself out from [tick], every frame, against the
/// scene's size.
///
/// Layout only ever flows from a [LayoutNode] to its direct children, so a
/// plain node in between doesn't pass constraints through - it starts a fresh
/// layout root underneath instead.
abstract class LayoutNode extends SpatialNode {
  final MVector2 _size = .zero();

  @override
  late final Shape shape = Rectangle(_size);

  @override
  set shape(Shape value) => throw UnsupportedError('A LayoutNode is sized by its layout.');

  /// How an ancestor `FlexNode` shares its leftover main-axis space with this
  /// node, ignored without one. Defaults to [LayoutFlex.none].
  @override
  LayoutFlex flex;

  LayoutNode({
    LayoutFlex? flex,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : flex = flex ?? .none;

  /// The items this node lays out: its direct [SpatialNode] children.
  ///
  /// Queried as [SpatialNode] rather than [LayoutItem] because that is what a
  /// layout item is *in the tree* - [LayoutItem] exists so `LayoutEngine` can
  /// work on things that aren't nodes at all.
  ///
  /// [Node.query] hands back live storage that is maintained in place rather
  /// than replaced, so the reference is resolved once and kept; later adds and
  /// removals show up through it.
  @protected
  late final Iterable<LayoutItem> layoutChildren = query<SpatialNode>();

  /// Whether no [LayoutNode] lays this node out, leaving it to lay itself out
  /// against the scene every frame.
  bool get isLayoutRoot => parent is! LayoutNode;

  /// Lays out this node under [constraints] and stores the result.
  @nonVirtual
  @override
  void layout(LayoutConstraints constraints) {
    final size = constrain(constraints);
    _size.setFrom(constraints.constrain(size.x, size.y));
  }

  /// Computes and returns this node's size under [constraints], laying out
  /// and positioning every [LayoutItem] child.
  ///
  /// The returned size need not satisfy [constraints]; [layout] clamps it.
  @visibleForOverriding
  Vector2 constrain(LayoutConstraints constraints);

  @override
  void build() {
    super.build();

    tick((_) {
      if (!isLayoutRoot) {
        return;
      } else if (!isMounted || !scene.hasSize) {
        layout(const .unbounded());
      } else {
        layout(.loose(scene.size));
      }
    });

    debugDraw((canvas) {
      final debug = Ignis.debug;
      if (!debug.draws(.layout)) return;
      canvas.drawRect(.fromLTWH(0, 0, width, height), debug.paint);
    });
  }
}
