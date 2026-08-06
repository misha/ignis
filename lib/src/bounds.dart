import 'package:ignis/src/math.dart';
import 'package:ignis/src/node.dart';
import 'package:ignis/src/nodes/transform_node.dart';
import 'package:ignis/src/shape.dart';

final _CENTER_SCRATCH = Vector2.zero();
final _HALF_EXTENTS_SCRATCH = Vector2.zero();

/// Computes [node]'s world-space AABB for [shape], writing the result into
/// [bounds]. The ancestor walk stops at (but does not include) [upTo].
///
/// TODO: Can't help but think this should live somewhere else. TransformNode?
void computeWorldBounds(
  TransformNode node,
  Shape shape,
  MutableAabb2 bounds, [
  Node? upTo,
]) {
  // Start with the total transform between the node and [upTo].
  final transform = node.absoluteTransform(upTo);
  final width = shape.width(node.size);
  final height = shape.height(node.size);
  final anchor = node.anchor;

  // Compute the shape's center, adjusted for the anchor and absolute transform.
  _CENTER_SCRATCH.mutate()
    ..setValues(width * (0.5 - anchor.x), height * (0.5 - anchor.y))
    ..transformWith(transform);

  // Compute the shape's half-extents, adjusted for absolute rotation (*not* transform).
  _HALF_EXTENTS_SCRATCH.mutate()
    ..setValues(width / 2, height / 2)
    ..absoluteRotate2With(transform);

  // Write the results to the provided AABB.
  bounds.setCenterAndHalfExtents(_CENTER_SCRATCH, _HALF_EXTENTS_SCRATCH);
}
