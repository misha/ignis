// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
import 'package:ignis/src/nodes/spatial_node.dart';
import 'package:ignis/src/shape.dart';

/// What a [SpatialNode]'s shape falls back to when it states none.
enum ShapeInheritance {
  /// Nothing: the node is a point.
  none,

  /// The nearest spatial ancestor's shape, or nothing without one.
  parent,

  /// The nearest spatial ancestor's shape, or the scene's without one.
  scene,
}

/// Resolves the shape a node inherits, per a [ShapeInheritance].
sealed class ShapeTarget extends Target<SpatialNode?> {
  factory ShapeTarget(Node host, ShapeInheritance policy) {
    return switch (policy) {
      .none => _NoneShapeTarget(host),
      .parent => _ParentShapeTarget(host),
      .scene => _SceneShapeTarget(host),
    };
  }

  ShapeTarget._(super.host);

  /// The inherited shape.
  Shape get shape;
}

class _NoneShapeTarget extends ShapeTarget {
  _NoneShapeTarget(super.host) : super._();

  @override
  Shape get shape => .none;
}

class _ParentShapeTarget extends ShapeTarget {
  _ParentShapeTarget(super.host) : super._();

  @override
  Shape get shape => value?.shape ?? .none;
}

class _SceneShapeTarget extends ShapeTarget {
  _SceneShapeTarget(super.host) : super._();

  @override
  Shape get shape => value?.shape ?? (host.isMounted ? host.scene.shape : .none);
}
