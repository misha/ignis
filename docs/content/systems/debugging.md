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

`Ignis.debug` allows you to set a `DebugMode` bitmask. Each bit in `DebugMode` toggles a certain type of wireframe in all live `Scene` objects.

| Mode         | Renders                                                      |
|--------------|--------------------------------------------------------------|
| `none`       | Nothing.                                                     |
| `transforms` | `TransformNode` origins and `SpriteNode`/`ShapeNode` bounds. |
| `collisions` | `ColliderNode` bounds.                                       |
| `inputs`     | `InputNode` hit areas.                                       |
| `layouts`    | `LayoutNode` boxes.                                          |
| `all`        | All debug wireframes.                                        |

You can also customize the `Paint` for each debug mode. For example, `Ignis.debug.inputPaint` specifies how `InputNode` will draw its debug visuals.

## `DebugControlsNode`

`DebugControlsNode` sets up standard debugging controls for any scene, binding several common debugging actions to `Ignis.controls`. The key(s) that trigger each action are completely customizable.

| Key  | Action                                                |
|------|-------------------------------------------------------|
| `F1` | Toggles the `transforms` debug mode.                  |
| `F2` | Toggles the `collisions` debug mode.                  |
| `F3` | Toggles the `inputs` debug mode.                      |
| `F4` | Toggles the `layouts` debug mode.                     |
| `F5` | Pauses and resumes the scene.                         |
| `F6` | Fills to the `all` debug mode, then clears to `none`. |

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
