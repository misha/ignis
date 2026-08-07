import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/transform_node.dart';

extension NearestTransformNode<T extends TransformNode> on Iterable<T> {
  /// The element whose [TransformNode.position] is closest to [position], or
  /// null if this is empty.
  T? nearest(Vector2 position) {
    T? closest;
    var closestDistance2 = double.infinity;

    for (final element in this) {
      final distance2 = element.position.distance2(position);

      if (distance2 < closestDistance2) {
        closest = element;
        closestDistance2 = distance2;
      }
    }

    return closest;
  }
}
