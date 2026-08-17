---
title: Sprites
description: Cutting a sheet into frames, and playing them.
lane: usage
category: system
status: complete
reference: [SpriteNode, Spritesheet]
related: [/systems/assets, /concepts/nodes, /concepts/live-reload]
---

## Overview

<Demo name="sprite-animation" hero/>

A *sprite* is an image or a sequence of images in a game. It usually refers to a single visual entity on the screen. A *spritesheet* is a single image that packs multiple frames for a single sprite in render order.

In Ignis, `SpriteNode` draws sprites. To do so, it requires a `Spritesheet`, which cuts an image into frames. The process is the same whether you want to render an image, play an animation, or switch between animations:

1. [Preload](/systems/assets) the assets.
2. Define a `Spritesheet`.
3. Pass it to a `SpriteNode`.

## Usage notes

- If you don't pass a `size` to `Spritesheet.asset(key, [size])`, it treats the asset as a single image.
- If you pass a `size`, `Spritesheet.asset` cuts the image into a grid of equally sized frames, numbered row-major from the top left. A 128x64 image with a 32x32 `size` holds 8 frames:

```
    0              128
  0 +---+---+---+---+
    | 0 | 1 | 2 | 3 |
    +---+---+---+---+
    | 4 | 5 | 6 | 7 |
 64 +---+---+---+---+
```

- `SpriteNode` comes with a `reassemble` implementation that allows it to reload images in live scenes when using the [local asset bundle](/concepts/live-reload#reloading-assets).

## Known limitations

- You cannot play an animation across two rows.
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
