import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:ignis/src/debug.dart';
import 'package:ignis/src/layout_constraints.dart';
import 'package:ignis/src/layout_engine.dart';
import 'package:ignis/src/layout_flex.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/node.dart';
import 'package:ignis/src/nodes/sized_node.dart';

/// A [SizedNode] whose size is computed via constraint propagation, rather
/// than being intrinsic to its content.
///
/// A [LayoutNode] no other [LayoutNode] claims is a layout root: it lays
/// itself out from [tick], every frame, against the scene's size. A claimed
/// one is laid out by its claimer instead, via a direct [layout] call inside
/// that node's [constrain].
abstract class LayoutNode extends SizedNode {
  final MVector2 _size = .zero();
  final List<Measurable> _layoutChildren = [];
  bool _layoutChildrenDirty = true;

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

  /// The items this node lays out: every nearest [Measurable] descendant,
  /// found by descending through the plain nodes between them.
  ///
  /// Resolved once and reused until a structural change invalidates it, so
  /// this is a cheap read on a stable tree. The returned list is owned by
  /// this node, and must not be retained or modified.
  @protected
  List<Measurable> get layoutChildren {
    if (_layoutChildrenDirty) {
      _layoutChildren.clear();
      _collect(this, _layoutChildren);
      _layoutChildrenDirty = false;
    }

    return _layoutChildren;
  }

  static void _collect(Node node, List<Measurable> items) {
    for (final child in node.children) {
      if (child case final Measurable item) {
        items.add(item);
      } else {
        _collect(child, items);
      }
    }
  }

  @override
  bool absorbStructuralChange() {
    _layoutChildrenDirty = true;
    return true;
  }

  /// Whether no [LayoutNode] claims this node, leaving it to lay itself out
  /// against the scene every frame.
  ///
  /// Mirrors how [layoutChildren] descends, so the two always agree on who
  /// lays out whom.
  bool get isLayoutRoot {
    var node = parent;

    while (node != null && node is! Measurable) {
      node = node.parent;
    }

    return node is! LayoutNode;
  }

  /// Lays out this node under [constraints] and stores the result.
  @nonVirtual
  void layout(LayoutConstraints constraints) {
    final size = constrain(constraints);
    _size.setFrom(constraints.satisfy(size.x, size.y));
  }

  /// Lays this node out under [constraints], then returns its resulting size.
  @override
  Vector2 measure(LayoutConstraints constraints) {
    layout(constraints);
    return size;
  }

  /// Computes and returns this node's size under [constraints], laying out
  /// and positioning every [Measurable] child.
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
    if (!isLayoutRoot) return;
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
