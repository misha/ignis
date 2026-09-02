---
title: Built-in Nodes
description: The nodes you construct, and what distinguishes each.
lane: usage
category: system
status: complete
---
<!-- SPDX-AI-Disclosure: none -->

## Core Nodes

| Node                 | Purpose                                                         | Signals                                 |
|----------------------|-----------------------------------------------------------------|-----------------------------------------|
| `Node`               | Base node specifying `enabled`, `priority`, and `children`.     | `onMount`, `onUnmount`, `onSceneResize` |
| `ColliderNode`       | Registers its `Shape` with the nearest `CollisionArenaNode`.    | `onCollisionStart`, `onCollisionEnd`    |
| `CollisionArenaNode` | Holds a `CollisionArena`.                                       | -                                       |
| `FpsNode`            | Tracks a rolling-window average frame rate in `fps`.            | `onFpsChange`                           |
| `ShapeNode`          | Draws a `Shape`.                                                | -                                       |
| `SpatialNode`        | Base spatial node with a transform and a `Shape`.               | -                                       |
| `SpriteNode`         | Animates a `Sprite`. See [Sprites](/systems/sprites).           | `onLoop`, `onFinish`                    |
| `TextNode`           | Draws text with `TextPainter`, wrapping to fit.                 | -                                       |
| `TextStyleNode`      | Holds the base `TextStyle` every descendant `TextNode` extends. | `onStyleChange`                         |
| `TimerNode`          | Tracks time to power its signal.                                | `onTrigger`                             |

`SpatialNode` is particularly impactful. Any system that integrates with 2D space typically *starts* from `SpatialNode`. This includes shapes, sprites, text, collisions, and layouts.

## Effect Nodes

See [Effects](/systems/effects).

| Node               | Purpose                                                          | Signals                                   |
|--------------------|------------------------------------------------------------------|-------------------------------------------|
| `EffectNode`       | Base node for time-driven effects, with a `cleanup` and `reset`. | `onFinish`                                |
| `CombinedEffect`   | Runs its effects together, finishing once every one has.         | `onFinish`                                |
| `TimelineEffect`   | An effect driven by a `Timeline`.                                | `onStart`, `onProgress`, `onMax`, `onMin` |
| `FollowEffect`     | Moves a `PositionOwner` toward what it follows, at a `speed`.    | `onFinish`                                |
| `SequentialEffect` | Chains its effects, adding the next once the previous ends.      | `onFinish`                                |
| `SpinEffect`       | Spins an `AngleOwner` by `speed`, every tick, forever.           | -                                         |
| `VelocityEffect`   | Moves a `PositionOwner` by `velocity`, every tick, forever.      | -                                         |

## Input Nodes

See [Inputs](/systems/inputs).

| Node         | Purpose                     | Signals                                                    |
|--------------|-----------------------------|------------------------------------------------------------|
| `InputNode`  | Base hit area for gestures. | -                                                          |
| `TapInput`   | Recognizes taps.            | `onTapDown`, `onTapUp`, `onTap`, `onTapCancel`             |
| `DragInput`  | Recognizes drags.           | `onDragStart`, `onDragUpdate`, `onDragEnd`, `onDragCancel` |
| `HoverInput` | Recognizes mouse hover.     | `onHoverEnter`, `onHoverExit`                              |

## Layout Nodes

See [Layout](/systems/layout).

| Node         | Purpose                                                                 | Signals |
|--------------|-------------------------------------------------------------------------|---------|
| `LayoutNode` | Base node for laid-out nodes.                                           | -       |
| `BoxNode`    | Claims a region, placing children under a shared padding and alignment. | -       |
| `FlexNode`   | Lays its children out along a `direction`, like Flutter's `Flex`.       | -       |
| `RowNode`    | Lays its children out horizontally, like Flutter's `Row`.               | -       |
| `ColumnNode` | Lays its children out vertically, like Flutter's `Column`.              | -       |
