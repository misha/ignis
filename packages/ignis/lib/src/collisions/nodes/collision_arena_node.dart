// SPDX-AI-Disclosure: none

import 'package:ignis/src/collisions/collision_arena.dart';
import 'package:ignis/src/collisions/nodes/collider_node.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/message.dart';

/// Steps a [CollisionArena] once per tick.
///
/// Descendant [ColliderNode]s automatically register with the nearest instance.
class CollisionArenaNode extends Node {
  /// The arena this node steps.
  final CollisionArena arena;

  CollisionArenaNode({
    CollisionArena? arena,
    super.enabled,
    super.priority,
    super.children,
  }) : arena = arena ?? CollisionArena() {
    provide<CollisionArena>(this.arena);
  }

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Update():
        arena.process();
    }
  }
}
