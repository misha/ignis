---
title: Sprites
description: Cutting a sheet into frames, and playing them.
lane: usage
category: system
status: complete
reference: [SpriteNode, Spritesheet]
---

<Demo name="sprite-animation" hero/>

A sprite is an image drawn by a node. Ignis has one class for it, `SpriteNode`, whether the image is a single picture or a sheet of frames played in order.

## Overview

Every sprite draws through a `Spritesheet`, which is what cuts an image into frames. Give it a frame size and the image becomes a grid, numbered from the top left along each row in turn. Omit the size and the sheet holds exactly one frame, so a still sprite and an animated one are the same node with the same parts.

```
+---+---+---+---+
| 0 | 1 | 2 | 3 |
+---+---+---+---+
| 4 | 5 | 6 | 7 |
+---+---+---+---+
```

The size has to divide the image evenly in both axes. Anything else throws an `ArgumentError` naming the axis that doesn't fit, at the moment you cut rather than at the frame that would have been drawn wrong.

Sheets read the asset cache rather than filling it, so the image has to be [preloaded](/systems/assets) before a sprite can ask for it. Every demo below preloads as it mounts, outside the code it shows.

`fps` is what sets a sprite running, and `play` is how you leave a row: it takes the sheet, the row, and the column to sit on.

<Warning>
A sprite plays one row at a time. Nothing advances past a row's last column - a four-row sheet holds four animations, not one long one.
</Warning>

<Why>
Every frame in a row lasts exactly as long as every other one, and there is no per-frame duration to set. Timing that varies belongs in the sheet, where you can already see it: the explosion below ends on four empty frames, and that is what holds the beat before it disappears.
</Why>

An animation set is rarely one sheet. `SpriteNode.split` takes several, and `play` chooses between them, so a character keeps one node however many states it has.

<Why>
One sheet per animation, rather than one row per animation in a single sheet. Rows in a grid are all as long as the longest of them, so a fourteen-frame idle sharing a sheet with a fifty-frame death spends most of its loop on empty frames. Separate sheets each end where their animation ends.
</Why>

A sprite draws one sheet, so a picture made of parts is made of nodes instead. Children draw in the order they are added, which is what puts the smoke behind the flame and the logs in front of it.

Finally, `loop: false` stops on the last frame of the row, sets `isFinished`, and emits `onFinish`. Adding `cleanup: true` detaches the node right after, which is the whole of a fire-and-forget effect.

## Examples

### A single image

<Demo name="sprite-still"/>

### Playing a sheet

<Demo name="sprite-animation"/>

### Switching sheets

<Demo name="sprite-split" hint="Try tapping!"/>

### Combining sprites

<Demo name="sprite-layers"/>

### Playing once

<Demo name="sprite-finish" hint="Try tapping!"/>

## Surviving a reload

`SpriteNode` is the one node in the engine that answers `reassemble` without rebuilding itself. It re-resolves each of its sheets against the cache and clamps the current frame if the replacement is shorter, so repainting a `.png` while the scene runs swaps the art under a sprite that never stops playing.

That is worth knowing because it is the exception. Everywhere else, [live reload](/concepts/live-reload) works by running `build` again; here the node's own state is what has to survive, and `SpriteNode.reassemble` is all of it.
