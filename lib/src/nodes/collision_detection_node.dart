import 'package:ignis/src/collision_detection.dart';
import 'package:ignis/src/node.dart';
import 'package:ignis/src/nodes/collider_node.dart';

/// Steps a [CollisionDetection] arena once per tick.
///
/// Descendant [ColliderNode]s automatically register with the nearest instance.
class CollisionDetectionNode extends Node {
  final CollisionDetection _arena;

  CollisionDetectionNode({
    CollisionDetection? arena,
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
