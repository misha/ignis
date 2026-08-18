---
title: Sprites
description: Cutting a sheet into frames, and playing them.
lane: usage
category: system
status: complete
reference: [SpriteNode, Sprite, SpriteImage, SpriteSheet, SheetRow, SpriteGroup]
related: [/systems/assets, /concepts/nodes, /systems/live-reload]
---

<Demo name="sprite-animation" hero/>

A *sprite* is an image or a sequence of images in a game. It refers to a single visual entity on the screen.

In Ignis, `SpriteNode` draws `Sprite`s. `Sprite` defines properties inherent to the art: the number and size of its frames, how fast it should play, and whether it loops. `SpriteNode` acts as a controller, selecting the appropriate frame on demand. The process is the same whether you want to render an image or play an animation: [preload](/systems/assets) assets, create a `Sprite`, then pass it to a `SpriteNode`.

There are several kinds of `Sprite`, depending on what you need to draw.

- `SpriteImage` represents one whole image.
- `SpriteSheet` cuts an image into frames for animation.
- `SpriteGroup` lays several `Sprite`s together, end to end.

These `Sprite` implementations automatically work with the [local asset bundle](/systems/live-reload#reloading-assets), allowing `SpriteNode` to reload images in live scenes as they change on disk.

`Sprite` itself is `abstract`, so it is straightforward to implement one for images stored in complex ways, such as when packed optimally by an art application or sprite packer.

<Warning>

  `SpriteSheet` cannot hold animations that wrap across multiple rows or skip frames. A single animation must be specified contiguously on one row.

</Warning>

<Lineage from="Flame">

  The APIs for `SpriteSheet` and `SpriteGroup` are heavily inspired by their corresponding classes in Flame.

</Lineage>

## Examples

### A single image

<Demo name="sprite-still"/>

### Playing a sheet

<Demo name="sprite-animation"/>

### Combining sprites

<Demo name="sprite-layers"/>

### Packing a sheet

<Demo name="sprite-rows" hint="Try tapping!"/>

### Naming rows

<Demo name="sprite-keys" hint="Try tapping!"/>

### Setting a rate per row

<Demo name="sprite-rates"/>

### Playing part of a row

<Demo name="sprite-partial"/>

### Timing frames by hand

<Demo name="sprite-timed"/>

### Scaling the rate

<Demo name="sprite-speed"/>

### Switching sheets

<Demo name="sprite-group" hint="Try tapping!"/>

### Reporting progress

<Demo name="sprite-signals"/>

### Playing once

<Demo name="sprite-finish" hint="Try tapping!"/>
