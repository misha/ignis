// SPDX-AI-Disclosure: none

import 'package:ignis/src/collisions/collision_arena.dart';
import 'package:ignis/src/collisions/nodes/collider_node.dart';
import 'package:ignis/src/core.dart';

/// Steps a [CollisionArena] once per tick.
///
/// Descendant [ColliderNode]s automatically register with the nearest instance.
class CollisionArenaNode extends Node {
  final CollisionArena _arena;

  CollisionArenaNode({
    CollisionArena? arena,
    super.enabled,
    super.priority,
    super.children,
  }) : _arena = arena ?? CollisionArena();

  @override
  void build() {
    super.build();

    tick((_) {
      _arena.process();
    });
  }

  void register(ColliderNode collider) {
    _arena.add(collider);
  }

  void unregister(ColliderNode collider) {
    _arena.remove(collider);
  }
}
