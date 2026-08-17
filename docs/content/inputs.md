---
title: Inputs
description: Hit areas that recognize pointer gestures, and how they compose.
---

`InputNode` is a hit area that recognizes pointer gestures by delegating to Flutter's own gesture
recognizers. It carries its own shape, so it is free to cover an area larger or smaller than whatever
it represents.

The demo below is a `DragInput` on a piece, and two zones that report collisions with it. Drag the
square onto a zone.

<DragAndDropDemo/>

That status line is not painted inside the scene. It is HTML on this page, updated by a signal the
scene emits — the page and the engine share Dart state directly.

## The inputs

| Input        | Purpose             | Signals                                                    |
|--------------|---------------------|------------------------------------------------------------|
| `TapInput`   | Recognizes taps.    | `onTapDown`, `onTapUp`, `onTap`, `onTapCancel`             |
| `DragInput`  | Recognizes drags.   | `onDragStart`, `onDragUpdate`, `onDragEnd`, `onDragCancel` |
| `HoverInput` | Tracks mouse hover. | `onHoverEnter`, `onHoverExit`                              |

A node wanting more than one gesture just adds more input nodes.

## Wiring one up

Inputs are declared in `build()`, like any other behavior. The piece above is a `ShapeNode` that adds
a slightly larger `DragInput` over itself, so it is easier to grab than it is to hit exactly.

```dart
class PieceNode extends ShapeNode {
  PieceNode({required super.position})
    : super(
        shape: .square(60),
        anchor: .center,
        paint: Paint()..color = const Color(0xFFFFAB40),
      );

  @override
  void build() {
    super.build();

    final drags = add(
      DragInput(
        shape: .square(shape.width + 20),
        anchor: anchor,
      ),
    );

    drags.onDragUpdate((event) {
      position.add(event.delta);
    });
  }
}
```

## Overlap and fallthrough

When multiple input nodes overlap, `priority` decides who is tried first. An event a node does not
apply to — a `HoverInput` receiving a tap, say — falls through to the next input node. Once a node
*does* claim an event the search stops there, unless its `behavior` is `HitBehavior.translucent`.

<Info>
  Hit testing walks children in reverse `priority` order before the node's own hit area, mirroring
  reverse paint order. The topmost thing you can see is the first thing tried.
</Info>

## Embedding notes

This page is a Flutter view embedded in an HTML document, which means the scene and the page
negotiate over the pointer:

- The scene does **not** take focus when it mounts. `SceneWidget.autofocus` defaults to `true`, which
  is right for a game filling the window and wrong for a demo inside prose — it would scroll the
  reader down to the demo on load. This page passes `autofocus: false`.
- Ignis has no cursor API, so the piece does not change the pointer on hover. `HoverInput` tracks
  hover state, but nothing maps that to a `MouseCursor`.
