import 'package:ignis/src/collisions/collision_detection.dart';
import 'package:ignis/src/collisions/nodes/collider_node.dart';
import 'package:ignis/src/core.dart';

/// Steps a [CollisionDetection] arena once per tick.
///
/// Descendant [ColliderNode]s automatically register with the nearest instance.
class CollisionDetectionNode extends Node {
  final CollisionDetection _arena;

  CollisionDetectionNode({
    CollisionDetection? arena,
    super.enabled,
    super.priority,
    super.children,
  }) : _arena = arena ?? CollisionDetection();

  @override
  void tick(double dt) {
    _arena.process();
  }

  void register(ColliderNode collider) {
    _arena.add(collider);
  }

  void unregister(ColliderNode collider) {
    _arena.remove(collider);
  }
}
