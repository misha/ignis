// SPDX-AI-Disclosure: none

import 'dart:math' as math;
import 'dart:ui';

import 'package:flutter/foundation.dart';
import 'package:ignis/src/anchor.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/globals.dart';
import 'package:ignis/src/layout/layout_constraints.dart';
import 'package:ignis/src/layout/layout_flex.dart';
import 'package:ignis/src/layout/layout_item.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/owners/anchor_owner.dart';
import 'package:ignis/src/owners/angle_owner.dart';
import 'package:ignis/src/owners/position_owner.dart';
import 'package:ignis/src/owners/scale_owner.dart';
import 'package:ignis/src/shape.dart';
import 'package:ignis/src/targets/shape_target.dart';

/// A [Node] with a transform and a shape.
class SpatialNode extends Node
    implements PositionOwner, ScaleOwner, AngleOwner, AnchorOwner, LayoutItem {
  /// This node's position. Defaults to (0, 0).
  @override
  final MVector2 position;

  /// This node's scale. Defaults to (1, 1).
  @override
  final MVector2 scale;

  /// This node's clockwise rotation, in radians. Defaults to 0.
  @override
  double angle;

  /// Where this node's area sits relative to [position]. Defaults to `topLeft`.
  @override
  Anchor anchor;

  /// What [shape] falls back to when this node states none. Defaults to
  /// [ShapeInheritance.none].
  final ShapeInheritance inherit;

  Shape _shape;
  late final _inherited = ShapeTarget(this, inherit);

  /// This node's shape.
  ///
  /// If the shape has a size of zero, it falls back to the [inherit]ed shape.
  Shape get shape => _shape.size.isZero ? _inherited.shape : _shape;

  /// Sets this node's own shape. Nodes sized by their content refuse one.
  set shape(Shape value) => _shape = value;

  SpatialNode({
    Shape? shape,
    ShapeInheritance? inherit,
    Vector2? position,
    Vector2? scale,
    double? angle,
    Anchor? anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : _shape = shape ?? .none,
       inherit = inherit ?? .none,
       position = .copy(position ?? .zero),
       scale = .copy(scale ?? .all(1)),
       angle = angle ?? 0,
       anchor = anchor ?? .topLeft;

  /// This node's dimensions, determined by the bounds of its [shape].
  @override
  Vector2 get size => shape.size;

  /// This node's width.
  @override
  double get width => size.x;

  /// This node's height.
  @override
  double get height => size.y;

  /// The [anchor]'s point in this node's local space.
  Vector2 pointAt(Anchor anchor) => .new(anchor.x * width, anchor.y * height);

  /// The center of this node's [shape], in its local space.
  ///
  /// [absoluteCenter] is the same point in scene space.
  Vector2 get center => pointAt(.center);

  /// The share of a flex layout's leftover space this node asks for.
  ///
  /// A plain node asks for none.
  @override
  LayoutFlex get flex => .none;

  /// A node that can't lay itself out takes no part in it, so [constraints]
  /// change nothing.
  @override
  void layout(LayoutConstraints constraints) {}

  /// The distance between this node's absolute center and [other]'s.
  double distance(SpatialNode other) => absoluteCenter.distance(other.absoluteCenter);

  /// The squared distance between this node's absolute center and [other]'s.
  double distance2(SpatialNode other) => absoluteCenter.distance2(other.absoluteCenter);

  final MMatrix3 _lastLocalTransform = .identity();

  /// This node's local transform.
  ///
  /// The returned matrix is owned by this node and should not be retained.
  MMatrix3 get localTransform {
    final transform = _lastLocalTransform;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final a = cosA * scale.x;
    final b = sinA * scale.x;
    final c = -sinA * scale.y;
    final d = cosA * scale.y;

    final anchor = this.anchor;

    if (anchor.isZero) {
      transform.setValues(
        // dart format off
        a, b, 0,
        c, d, 0,
        position.x, position.y, 1,
        // dart format on
      );

      return transform;
    }

    final offsetX = -anchor.x * width;
    final offsetY = -anchor.y * height;

    transform.setValues(
      // dart format off
      a, b, 0,
      c, d, 0,
      offsetX * a + offsetY * c + position.x,
      offsetX * b + offsetY * d + position.y, 1,
      // dart format on
    );

    return transform;
  }

  final MMatrix3 _lastAbsoluteTransform = .identity();

  /// This node's transform composed with every [SpatialNode] ancestor,
  /// stopping at (but not including) [upTo].
  ///
  /// The returned matrix is owned by this node and should not be retained.
  MMatrix3 absoluteTransform([Node? upTo]) {
    final transform = _lastAbsoluteTransform;
    transform.setFrom(localTransform);
    var current = parent;

    while (current != null && !identical(current, upTo)) {
      if (current is SpatialNode) {
        transform.premultiply(current.localTransform);
      }

      current = current.parent;
    }

    return transform;
  }

  /// This node's [position], composed with the transform of every
  /// [SpatialNode] ancestor, stopping at (but not including) [upTo].
  ///
  /// The returned vector is owned by the caller.
  MVector2 scenePosition([Node? upTo]) {
    final absolute = MVector2.copy(position);
    var current = parent;

    while (current != null && !identical(current, upTo)) {
      if (current is SpatialNode) {
        absolute.transform(current.localTransform);
      }

      current = current.parent;
    }

    return absolute;
  }

  /// This node's [position] in scene space.
  ///
  /// The returned vector is owned by the caller.
  MVector2 get absolutePosition => scenePosition();

  /// The center of this node's [shape] in scene space.
  ///
  /// The returned vector is owned by the caller.
  MVector2 get absoluteCenter => .copy(size)
    ..scale(0.5)
    ..transform(absoluteTransform());

  /// The nearest [T] to this node among [within]'s descendants, or null if
  /// there is none.
  ///
  /// Defaults to searching this node's whole tree. Never returns this node.
  T? nearest<T extends SpatialNode>([Node? within]) {
    var root = within;

    if (root == null) {
      root = this;

      while (root!.parent != null) {
        root = root.parent;
      }
    }

    final absolute = absoluteCenter;
    T? closest;
    var closestDistance2 = double.infinity;

    for (final descendant in root.descendants) {
      if (descendant is! T || identical(descendant, this)) continue;

      final distance2 = descendant.absoluteCenter.distance2(absolute);

      if (distance2 < closestDistance2) {
        closest = descendant;
        closestDistance2 = distance2;
      }
    }

    return closest;
  }

  final _lastRenderTransform = Float64List(16)
    ..[10] = 1
    ..[15] = 1;

  /// This node's render transform. Equivalent to [localTransform], except
  /// that it's stored in a [Canvas]-friendly `typed_data` structure for
  /// performance reasons.
  ///
  /// The returned float list is owned by this node and should not be retained.
  Float64List get _renderTransform {
    final transform = _lastRenderTransform;
    final cosA = math.cos(angle);
    final sinA = math.sin(angle);

    final a = cosA * scale.x;
    final b = sinA * scale.x;
    final c = -sinA * scale.y;
    final d = cosA * scale.y;

    final anchor = this.anchor;

    if (anchor.isZero) {
      transform
        ..[0] = a
        ..[1] = b
        ..[4] = c
        ..[5] = d
        ..[12] = position.x
        ..[13] = position.y;

      return transform;
    }

    final offsetX = -anchor.x * width;
    final offsetY = -anchor.y * height;

    transform
      ..[0] = a
      ..[1] = b
      ..[4] = c
      ..[5] = d
      ..[12] = offsetX * a + offsetY * c + position.x
      ..[13] = offsetX * b + offsetY * d + position.y;

    return transform;
  }

  static final _CENTER_SCRATCH = MVector2.zero();
  static final _HALF_EXTENTS_SCRATCH = MVector2.zero();

  final MAabb2 _lastWorldBounds = .zero();

  /// This node's world-space AABB for [shape], given its already-computed
  /// [transform] (see [absoluteTransform]).
  ///
  /// The returned AABB is owned by this node and should not be retained.
  Aabb2 worldBounds(Shape shape, Matrix3 transform) {
    final bounds = _lastWorldBounds;
    final width = shape.width;
    final height = shape.height;

    // The anchor rides in the transform, so the shape's center sits at half its
    // extent in the node's own space.
    _CENTER_SCRATCH
      ..setValues(width / 2, height / 2)
      ..transform(transform);

    // Compute the shape's half-extents, adjusted for absolute rotation (*not* transform).
    _HALF_EXTENTS_SCRATCH
      ..setValues(width / 2, height / 2)
      ..absoluteRotate(transform);

    bounds.setCenterAndHalfExtents(_CENTER_SCRATCH, _HALF_EXTENTS_SCRATCH);
    return bounds;
  }

  @override
  void render(Canvas canvas) {
    canvas.save();
    canvas.transform(_renderTransform);
    super.render(canvas);
    canvas.restore();
  }

  /// Renders the subtree under this node's transform, marking [position] with
  /// a 2-pixel cross before anything this node or its children draw.
  ///
  /// The cross draws under every [DebugMode], in that mode's own color, so a
  /// wireframe of one category still says where each node sits.
  /// [DebugMode.spatial] adds the bounds.
  ///
  /// Overridden rather than drawn through [debugDraw] because the transform
  /// has to wrap the children too, and a callback would cost every node in the
  /// engine a list and a closure it may never use.
  @override
  void debugRender(Canvas canvas) {
    canvas.save();
    canvas.transform(_renderTransform);

    final debug = Ignis.debug;
    final paint = debug.paint;
    final x = anchor.x * width;
    final y = anchor.y * height;

    canvas.drawLine(.new(x - 1, y), .new(x + 1, y), paint);
    canvas.drawLine(.new(x, y - 1), .new(x, y + 1), paint);

    if (debug.draws(.spatial)) {
      canvas.drawRect(shape.rect(), paint);
    }

    super.debugRender(canvas);
    canvas.restore();
  }
}
