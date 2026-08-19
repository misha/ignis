import 'package:flutter/foundation.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/layout/layout_constraints.dart';
import 'package:ignis/src/layout/layout_flex.dart';
import 'package:ignis/src/layout/layout_item.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/sized_node.dart';

/// A [SizedNode] whose size is computed via constraint propagation, rather
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
abstract class LayoutNode extends SizedNode {
  final MVector2 _size = .zero();

  @override
  Vector2 get size => _size;

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

  /// The items this node lays out: its direct [SizedNode] children.
  ///
  /// Queried as [SizedNode] rather than [LayoutItem] because that is what a
  /// layout item is *in the tree* - [LayoutItem] exists so `LayoutEngine` can
  /// work on things that aren't nodes at all.
  ///
  /// [Node.query] hands back live storage that is maintained in place rather
  /// than replaced, so the reference is resolved once and kept; later adds and
  /// removals show up through it.
  @protected
  late final Iterable<LayoutItem> layoutChildren = query<SizedNode>();

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
      if (!isLayoutRoot) return;
      layout(_rootConstraints());
    });

    debugDraw((canvas) {
      final debug = Ignis.debug;
      if (!debug.draws(.layouts)) return;
      canvas.drawRect(.fromLTWH(0, 0, width, height), debug.layoutPaint);
    });
  }

  /// A layout root is given the scene loosely, not tightly, so a node that
  /// asks for a size gets it. Filling is opt-in: set an `alignment`, a
  /// `mainAxisSize`, or a `crossAxisAlignment` that asks for the room.
  LayoutConstraints _rootConstraints() {
    if (!isMounted || !scene.hasSize) return .unbounded();
    return .loose(scene.size);
  }
}
