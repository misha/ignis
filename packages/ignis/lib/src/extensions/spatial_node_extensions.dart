// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/spatial_node.dart';

extension NearestSpatialNode<T extends SpatialNode> on Iterable<T> {
  /// The element nearest to [node], or null if this is empty.
  ///
  /// Never returns [node] itself.
  T? nearest(SpatialNode node) => nearestTo(node.absoluteCenter, excluded: node);

  /// The element nearest to [position], or null if this is empty.
  ///
  /// [position] is in scene space, so the elements need not share a parent.
  ///
  /// If [excluded] is provided, skips that node during traversal.
  T? nearestTo(Vector2 position, {Node? excluded}) {
    T? closest;
    var closestDistance2 = double.infinity;

    for (final element in this) {
      if (identical(element, excluded)) continue;

      final distance2 = element.absoluteCenter.distance2(position);

      if (distance2 < closestDistance2) {
        closest = element;
        closestDistance2 = distance2;
      }
    }

    return closest;
  }
}
