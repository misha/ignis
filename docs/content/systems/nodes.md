---
title: Nodes
description: The nodes you construct, and what distinguishes each.
lane: usage
category: system
status: complete
---

## Core Nodes

| Node                     | Purpose                                                          | Signals                                 |
|--------------------------|------------------------------------------------------------------|-----------------------------------------|
| `Node`                   | Base node specifying `enabled`, `priority`, and `children`.      | `onMount`, `onUnmount`, `onSceneResize` |
| `ColliderNode`           | Registers its `Shape` with the nearest `CollisionDetectionNode`. | `onCollisionStart`, `onCollisionEnd`    |
| `CollisionDetectionNode` | Holds a `CollisionDetection` arena.                              | -                                       |
| `FpsNode`                | Tracks a rolling-window average frame rate in `fps`.             | `onFpsChange`                           |
| `ShapeNode`              | Draws a `Shape`.                                                 | -                                       |
| `SizedNode`              | Base node with a size, used for shapes, sprites, and more.       | -                                       |
| `SpriteNode`             | Animates a `Sprite`. See [Sprites](/systems/sprites).            | `onFrame`, `onLoop`, `onFinish`         |
| `TextNode`               | Draws text with `TextPainter`, wrapping to fit.                  | -                                       |
| `TimerNode`              | Tracks time to power its signal.                                 | `onTrigger`                             |
| `TransformNode`          | Base spatial node with a `position`, `scale`, and `angle`.       | -                                       |

### Notable Core Nodes

`TransformNode` is the base spatial node. It carries a mutable `position`, `scale`, and `angle`, and reports `absolutePosition` for its place in the scene rather than in its parent.

```dart
final turret = add(TransformNode(position: Vector2(120, 40)));

turret.angle += 0.5 * dt;
turret.distance(target); // Between absolute positions.
```

`SizedNode` extends `TransformNode` with a `size` and an `anchor`. Shapes, sprites, layouts, and text are all sized nodes.

Additionally, the collision, input, and layout systems all *start* with `SizedNode`. Each one depends on a node that doesn't merely exist in space, but actually occupies it as well.

## Effect Nodes

See [Effects](/systems/effects).

| Node                | Purpose                                                       | Signals                                       |
|---------------------|---------------------------------------------------------------|-----------------------------------------------|
| `EffectNode`        | Base node for time-driven effects, with a `cleanup` and `reset`. | `onFinish`                                 |
| `CombinedEffect`    | Runs its effects together, finishing once every one has.      | `onFinish`                                    |
| `ControlledEffect`  | An effect driven by an `EffectController`.                    | `onStart`, `onProgress`, `onMax`, `onMin`     |
| `FollowEffect`      | Moves a `PositionOwner` toward what it follows, at a `speed`. | `onFinish`                                    |
| `SequentialEffect`  | Chains its effects, adding the next once the previous ends.   | `onFinish`                                    |
| `SpinEffect`        | Spins an `AngleOwner` by `speed`, every tick, forever.        | -                                             |
| `VelocityEffect`    | Moves a `PositionOwner` by `velocity`, every tick, forever.   | -                                             |

## Input Nodes

See [Inputs](/systems/inputs).

| Node         | Purpose                                              | Signals                                                    |
|--------------|------------------------------------------------------|------------------------------------------------------------|
| `InputNode`  | Base hit area for gestures.                          | -                                                          |
| `TapInput`   | Recognizes taps.                                     | `onTapDown`, `onTapUp`, `onTap`, `onTapCancel`             |
| `DragInput`  | Recognizes drags.                                    | `onDragStart`, `onDragUpdate`, `onDragEnd`, `onDragCancel` |
| `HoverInput` | Recognizes mouse hover.                              | `onHoverEnter`, `onHoverExit`                              |

## Layout Nodes

See [Layout](/systems/layout).

| Node         | Purpose                                                                   | Signals |
|--------------|---------------------------------------------------------------------------|---------|
| `LayoutNode` | Base node for laid-out nodes.                                             | -       |
| `BoxNode`    | Claims a region, placing children under a shared padding and alignment.   | -       |
| `FlexNode`   | Lays its children out along a `direction`, like Flutter's `Flex`.         | -       |
| `RowNode`    | Lays its children out horizontally, like Flutter's `Row`.                 | -       |
| `ColumnNode` | Lays its children out vertically, like Flutter's `Column`.                | -       |
