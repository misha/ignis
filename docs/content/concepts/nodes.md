---
title: Nodes
description: The tree, and where your code goes.
lane: usage
category: concept
status: complete
related: [/systems/nodes, /concepts/scenes, /concepts/signals]
internals: [/internals/tree]
---

`Node` is the primitive of Ignis.

Nodes are constructed in trees, inheriting the properties and transforms of their ancestors.

A node declares its behavior and children in `build()`, which runs whenever the node enters a scene. Per-frame logic is registered with `tick`, and drawing with `draw`.

<Demo name="spinner"/>

<Warning>

  `super.build()` is required. Skipping it drops whatever the superclass declared.

</Warning>

<Warning>

  **Never make `build()` `async`.** An asynchronous build breaks engine invariants in multiple, devastating ways.

</Warning>

For a complete list of available nodes, see [Built-in Nodes](/systems/nodes).

## Ticking and Drawing

`tick` registers a callback to run every frame with the elapsed seconds. Register as many as you like; each belongs to the build that declared it.

```dart
tick((dt) {
  position.addScaled(velocity, dt);
});
```

`draw` registers a callback to paint with, in the node's own coordinate space - the origin is wherever the node sits, anchor and all. Register as many as you like.

```dart
draw((canvas) {
  canvas.drawCircle(.zero, radius, paint);
});
```

Callbacks run before the node's children, so a parent paints behind them.

`debugDraw` is the same thing for the debug overlay, and runs whenever the overlay is on. See [Debugging](/systems/debugging).

```dart
debugDraw((canvas) {
  canvas.drawRect(shape.rect(), Ignis.debug.paint);
});
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

- `onMount` and `onUnmount` are emitted when that instance enters and exits a scene.
- `onSceneResize` is emitted once at mount and again whenever the scene changes size.

Other nodes expose signals based on their specific use case. For example, collider nodes offer `onCollisionStart` and `onCollisionEnd`, and a tap input node offers `onTap`.

## Cleaning Up

A signal watched inside `build()` is owned by the node and unsubscribed for you. See [Signals](/concepts/signals).

Anything else that has to be released goes in the `trash`, which is emptied at unmount, most recently thrown in first.

```dart
final painter = TextPainter(text: span);
trash(painter.dispose);
```
