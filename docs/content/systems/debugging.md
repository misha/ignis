---
title: Debugging
description: Seeing what the engine is actually doing.
lane: usage
category: system
status: complete
related: [/systems/globals]
reference: [Debug]
---
<!-- SPDX-AI-Disclosure: none -->

<Demo name="debug-wireframes" hero/>

Ignis ships with a handful of high-level debugging tools. But first, a demonstration.

This site binds the number `1` on your keyboard to the debug mode toggle. The status of each debug mode is reflected in the site's header.

## Debug Modes

`Ignis.debug` allows you to set a `DebugMode`, or `null` to draw nothing. The mode selects which type of wireframe is drawn in all live `Scene` objects.

| Mode        | Renders                           |
|-------------|-----------------------------------|
| `spatial`   | `SpatialNode` origin and extents. |

One mode draws at a time. `spatial` shows the most, covering every node that has a shape, drawn as its bounding box.

Every `SpatialNode` marks its origin with a small cross.

You can also customize the `Paint` for each debug mode.

## `debugDraw`

Wireframes are drawn on *top* of a scene by executing an additional rendering pass. Use `debugDraw` to add your own debug visuals to this secondary rendering pass:

```dart
// Only called when a debug mode is enabled:
debugDraw((canvas) {
  canvas.drawRect(shape.rect(), Ignis.debug.paint);
});
```

<Info>

  `debugDraw` follows the same rules and restrictions as `draw`.

</Info>

## Disclaimer

*No slimes were injured in the making of this page.*
