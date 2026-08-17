---
title: Collision detection
description: The arena, and the two phases it runs.
lane: internals
category: internal
status: stub
---

<!-- Walk lib/src/collisions/collision_detection.dart, intersection_system.dart, and nodes/collider_node.dart, in the order a frame runs them. -->

<!-- Diagram: the two phases as a plain fence.
     colliders -> layer/mask cull -> candidate pairs -> SAT -> contacts -> diff -> start/end signals -->

## The invariant

<!-- Contact is a set, and the signals are its edges. onCollisionStart and onCollisionEnd fire on the frames the set changes, never on the frames it holds - so a handler runs once per contact rather than once per frame of contact. -->

## Registering with the arena

<!-- lib/src/collisions/nodes/collider_node.dart. A collider finds the nearest CollisionDetectionNode ancestor in its own build() and puts the deregistration in the trash, so a rebuild cannot leave a stale collider in the arena. -->

## Broad phase

<!-- How pairs are culled by layer and mask bitmasks before any geometry is touched, and why both default to -1. This is where the cost is avoided; say what the pair count would otherwise be. -->

## Narrow phase

<!-- lib/src/collisions/intersection_system.dart. The separating axis test, and the circle/rectangle special cases. Explain SAT itself - it is the one piece here a reader may not already know. -->

## Diffing into edges

<!-- lib/src/collisions/collision_detection.dart. How this frame's contact set is compared against the last to produce start and end, and what happens to a contact whose collider left the tree mid-frame. -->

## What this doesn't do
