---
title: Collisions
description: Hitboxes, layers, and the two signals that report contact.
lane: usage
category: system
status: partial
reference: [CollisionDetectionNode, ColliderNode, Shape]
related: [/internals/collisions, /systems/shapes-anchors, /concepts/signals]
---

<Demo name="collision-balls" hero hint="Try dragging!"/>

Collisions work using two nodes, `CollisionDetectionNode` and `ColliderNode`.

`CollisionDetectionNode` sets up a collision detection arena. Whenever a `ColliderNode` is added to a scene, it finds the closest `CollisionDetectionNode` above it and registers itself.

Today, collision detection has two significant limitations:

- It works only with `Shape`: circles and rectangles.
- It only reports the other `ColliderNode`, not where they collided.

In exchange for these limitations, the arena is quite performant. See how many balls you can spawn before your FPS drops!

## Layers and Masks

`ColliderNode` supports specifying two bitmasks, `layer` and `mask`, to exclude certain collisions from consideration. `layer` indicates the physics layers the collider exists on, while `mask` indicates which physics layers it collides with. A pair only reports a collision to a side whose `mask` intersects the other's `layer`.

<Info>

  While `layer` and `mask` are defined as integers, they should be treated as bitmasks. Each position in the integer is a separate physics layer. That also means Ignis only supports up to 32 collision detection layers. By default, `layer` and `mask` are -1 (all bits are 1), letting all colliders interact.

</Info>

The code below excludes wall-wall collisions altogether, greatly improving collision detection performance and removing the need to handle those cases in your code.

```dart
const TERRAIN_LAYER = 1 << 0;
const UNIT_LAYER = 1 << 1;

wall
  ..layer = TERRAIN_LAYER
  ..mask = 0;

player
  ..layer = UNIT_LAYER
  ..mask = TERRAIN_LAYER | UNIT_LAYER;
```

<Lineage from="Godot">

  The names `layer` and `mask` come from Godot's collision system.

</Lineage>
