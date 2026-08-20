---
title: Sprites
description: Cutting art into frames, and playing them.
lane: usage
category: system
status: complete
reference: [SpriteNode, Sprite, SpriteImage, SpriteAnimation, SpriteRegion, SpriteSheet, SpriteMap, SpriteGroup]
related: [/systems/assets, /concepts/nodes, /systems/live-reload]
---

<Demo name="sprite-animation" hero/>

A *sprite* is an image or a sequence of images in a game. It refers to a single visual entity on the screen.

In Ignis, `SpriteNode` draws `Sprite`s. A `Sprite` states what the art decides: its frames, how fast they play, and whether they loop. `SpriteNode` acts as a controller, selecting the appropriate frame on demand. The process is the same whether you want to render an image or play an animation: [preload](/systems/assets) assets, create a `Sprite`, then pass it to a `SpriteNode`.

There are several kinds of `Sprite`, depending on what you need to draw.

- `SpriteImage` draws one still image.
- `SpriteAnimation` plays a run of frames.
- `SpriteGroup` lays several `Sprite`s together, end to end.
- `SpriteMap` names them.

These `Sprite` implementations automatically work with the [local asset bundle](/systems/live-reload#reloading-assets), allowing `SpriteNode` to reload images in live scenes as they change on disk.

`Sprite` itself is `abstract`, so it is straightforward to implement one for images stored in complex ways, such as when packed optimally by an art application or sprite packer.

## Sprite Sheets

Most games don't store sprites in individual images for performance reasons. Instead, they use *sprite sheets*, which encode multiple logical sprites into the same physical file.

Ignis provides a `SpriteSheet` to produce `Sprite`s using regions of a single image file. Note that a `SpriteSheet` itself is *not* a `Sprite`, but rather a means of acquiring one (or more) with minimal bookkeeping.

```dart
// Measure a grid of 56x56 frames over the image.
final sheet = SpriteSheet('assets/slime.png', Vector2.all(56));

// One cell of the grid, drawn still.
final tile = sheet.image(row: 0, column: 3);

// One row of the grid, or a span of one, played.
final jump = sheet.animation(row: 1, end: 30, fps: 24);

// Every row at once, end to end, each with its own parameters.
final slime = sheet.animations(fps: 16, rows: [.new(start: 6), .new(end: 30)]);
```

<Warning>

  `SpriteSheet` cannot hold animations that wrap across multiple rows. A single animation must be specified contiguously on one row.

</Warning>

<Lineage from="Flame">

  The APIs for `SpriteSheet`, `SpriteAnimation` and `SpriteGroup` are heavily inspired by their corresponding classes in Flame.

</Lineage>

## Examples

### A single image

<Demo name="sprite-still"/>

### Playing an animation

<Demo name="sprite-animation"/>

### Combining sprites

<Demo name="sprite-layers"/>

### Packing a sheet

<Demo name="sprite-rows" hint="Try tapping!"/>

### Naming sprites

<Demo name="sprite-keys" hint="Try tapping!"/>

### Setting a rate per animation

<Demo name="sprite-rates"/>

### Playing part of a row

<Demo name="sprite-partial"/>

### Working with tiles

<Demo name="sprite-tiles"/>

### Timing frames by hand

<Demo name="sprite-timed"/>

### Scaling the rate

<Demo name="sprite-speed"/>

### Mixing stills and animations

<Demo name="sprite-group" hint="Try tapping!"/>

### Reporting progress

<Demo name="sprite-signals"/>

### Playing once

<Demo name="sprite-finish" hint="Try tapping!"/>
