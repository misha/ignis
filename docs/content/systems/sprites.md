---
title: Sprites
description: Cutting a sheet into frames, and playing them.
lane: usage
category: system
status: complete
reference: [SpriteNode, Spritesheet]
related: [/systems/assets, /concepts/nodes, /concepts/live-reload]
---

<Demo name="sprite-animation" hero/>

A `SpriteNode` draws the frames a `Spritesheet` cuts from an image, whether that is one still picture, one animation, or a set of them. Repainting a `.png` while the scene runs swaps the art under a sprite that never stops playing, since a sprite is the one node that survives live reload without rebuilding.

## Overview

A `Spritesheet` cuts an image into a grid of equally sized frames, numbered row-major from the top left. Omit the frame size and the grid holds a single frame, which is what a still sprite draws.

```
+---+---+---+---+
| 0 | 1 | 2 | 3 |
+---+---+---+---+
| 4 | 5 | 6 | 7 |
+---+---+---+---+
```

A sprite plays along one row and never leaves it, so how a sheet is cut up is an authoring decision: a 4-row sheet holds 4 animations, and `play` moves between them. Every frame is held for the same length of time, so a sheet's own frames are where timing lives.

One node draws one sheet. A character with several animations keeps one node and several sheets through `SpriteNode.split`. A picture made of parts takes one node per part, drawn in [`priority`](/concepts/nodes) order.

## Known limitations

- You cannot play a row partially.
- You cannot set a per-row `fps`.
- You cannot set a per-frame `fps`.
- You cannot share one frame size across several sheets.

## Examples

### A single image

<Demo name="sprite-still"/>

### Playing a sheet

<Demo name="sprite-animation"/>

### Switching sheets

<Demo name="sprite-split" hint="Try tapping!"/>

### Combining sprites

<Demo name="sprite-layers"/>

### Reporting progress

<Demo name="sprite-signals"/>

### Playing once

<Demo name="sprite-finish" hint="Try tapping!"/>
