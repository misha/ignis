---
title: Nodes
description: The tree, and where your code goes.
lane: usage
category: concept
status: complete
related: [/systems/nodes, /concepts/scenes, /concepts/signals]
internals: [/internals/tree]
---
<!-- SPDX-AI-Disclosure: none -->

`Node` is the primitive of Ignis.

Nodes are constructed in trees, inheriting the properties and transforms of their ancestors.

A node declares its behavior and children in `build()`, which runs whenever the node enters a scene. Per-frame logic is registered with `tick`.

<Demo name="spinner"/>

<Warning>

  `super.build()` is required. Skipping it drops whatever the superclass declared.

</Warning>

<Warning>

  **Never make `build()` `async`.** An asynchronous build breaks engine invariants in multiple, devastating ways.

</Warning>

For a complete list of available nodes, see [Built-in Nodes](/systems/nodes).

## Building

Nodes install behavior in the `build` method, called whenever the node is mounted to a scene.

Behavior is composed from a mere three primitives: `tick`, `draw`, and `trash`. Each primitive takes a callback and registers it for execution. This apparently innocuous pattern simultaneously enables [Locality of Behavior](/motivation#locality-of-behavior) and [Live Reload](/systems/live-reload).

`tick` and `draw` callbacks are executed first-in-first-out, like a queue. `trash` callbacks are executed first-in-last-out, like a stack.

<Info>

  For `tick` and `draw`, a parent's callbacks run before their children's callbacks. For `draw`, this means parents always render beneath their children.

</Info>

<Warning>

  `tick`, `draw`, and `trash` may **only** be called inside `build`.

</Warning>

### Ticking

`tick` registers a callback to run every frame of the game loop. `dt` is the frame time in seconds. See [Time](/concepts/time).

```dart
tick((dt) {
  position.addScaled(velocity, dt);
});
```

### Drawing

`draw` registers a callback to paint something to the canvas. `canvas` is always in the node's own coordinate space. The origin is wherever the node exists in the tree.

```dart
draw((canvas) {
  canvas.drawCircle(.zero, radius, paint);
});
```

There is an additional drawing primitive, `debugDraw`, available for visual debugging purposes. See [Debugging](/systems/debugging).

### Trashing

`trash` registers a callback to run when the node is unmounted or rebuilt. It is most commonly used to clean up resources created for that node.

```dart
final painter = TextPainter(text: span);
trash(painter.dispose);
```

## Enabled

Nodes have an `enabled` flag, allowing you to dynamically activate or deactivate them in the tree. When disabled, the node will no longer tick or draw.

<Demo name="node-enabled" hint="Try tapping!"/>

Use the `enabled` flag to avoid micromanaging nodes that only need to run intermittently.

## Priority

A node's children are sorted by `priority`. Priority dictates the order in which children of the same node are processed, covering updating and rendering.

A node's default priority is 0. With this default, children are processed in the order in which they are `add`ed.

With `priority`, you can manually adjust this order. Consider the following examples:

By default, the two shapes are rendered in the order in which they are added.

<Demo name="node-priority-order"/>

Giving the first shape a higher priority causes it to be rendered on top, despite the second having been added later.

<Demo name="node-priority-lifted"/>

However, `priority` only applies to siblings of the same node. A child is *always* processed after its parent, and no amount of `priority` can change this.

<Demo name="node-priority-nested"/>

## Signals

`Node` comes with three signals, which makes them available on every node in the engine.

- `onMount` is emitted when entering a scene.
- `onUnmount` is emitted when exiting a scene.
- `onSceneResize` is emitted when entering a scene, and again whenever the scene changes size.

Signals watched inside `build` do not need to be unsubscribed from. See [Signals](/concepts/signals).
