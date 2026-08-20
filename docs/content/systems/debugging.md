---
title: Debugging
description: Seeing what the engine is actually doing.
lane: usage
category: system
status: complete
related: [/systems/globals, /systems/controls]
reference: [Debug, DebugControlsNode]
---

<Demo name="debug-wireframes" hero/>

Ignis ships with a handful of high-level debugging tools. But first, a demonstration.

This site binds the numbers `1` through `4` on your keyboard to debug mode toggles. The status of each debug mode is reflected in the site's header.

The demo on the right has a hidden input box. Hit `3` to find the input box, then tap it!

## Debug Modes

`Ignis.debug` allows you to set a `DebugMode`, or `null` to draw nothing. The mode selects which type of wireframe is drawn in all live `Scene` objects.

| Mode        | Renders                           |
|-------------|-----------------------------------|
| `spatial`   | `SpatialNode` origin and extents. |
| `collision` | `ColliderNode` shapes.            |
| `input`     | `InputNode` hit areas.            |
| `layout`    | `LayoutNode` boxes.               |

One mode draws at a time. `spatial` shows the most, covering every node that has a shape, drawn as its bounding box. The other three narrow to a single category, and draw its true shape rather than the box around it, so reach for them when `spatial` gives you more than you want to look at, or when you need a circle drawn as a circle.

Every `SpatialNode` marks its origin with a small cross under all four modes, drawn in that mode's own color, so narrowing to one category still tells you where each node sits.

You can also customize the `Paint` for each debug mode. For example, `Ignis.debug.inputPaint` specifies how `InputNode` will draw its debug visuals.

## `DebugControlsNode`

`DebugControlsNode` sets up standard debugging controls for any scene, binding several common debugging actions to `Ignis.controls`. The key(s) that trigger each action are completely customizable.

| Key  | Action                              |
|------|-------------------------------------|
| `F1` | Toggles the `spatial` debug mode.   |
| `F2` | Toggles the `collision` debug mode. |
| `F3` | Toggles the `input` debug mode.     |
| `F4` | Toggles the `layout` debug mode.    |
| `F5` | Pauses and resumes the scene.       |
| `F6` | Turns debug mode off.               |

Add it to your scenes in debug builds for instant debuggability:

```dart
@override
void build() {
  super.build();
  if (kDebugMode) add(DebugControlsNode());
}
```

<Info>

  If your game binds any of these keys, the default `priority` on `DebugControlsNode` will let your game respond instead.

</Info>

## Disclaimer

*No slimes were injured in the making of this page.*
