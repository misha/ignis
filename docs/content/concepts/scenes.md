---
title: Scenes
description: Mounting a tree, and why your edits land next frame.
lane: usage
category: concept
status: complete
---

A *scene* is a tree of nodes. Any node can be mounted as the root of a `Scene`. `Scene` wraps the tree with a size and offers methods to manipulate the entire tree effectively.

```dart
final game = GameNode();
final scene = game.mount(); // Ready to go!
```

## Flutter Usage

`SceneWidget` embeds a scene in Flutter. Flutter's engine will then automatically drive updating and rendering. You can control the loop using the widget's parameters:

```dart
final widget = SceneWidget(
  scene,
  paused: true, // Start the scene paused.
  debug: true,  // Enable debug rendering.
);
```

<Lineage from="Flame">

  Much of the Flutter integration is thanks to existing code from Flame.

</Lineage>

`SceneWidget` also owns the scene it is given, destroying it when the widget leaves the tree or is handed a different scene.

<Warning>

  Scene destruction is permanent. Mount a fresh scene to start over.

</Warning>

## Manual Usage

Scenes can also be driven completely manually. In fact, this is how much of Ignis is tested internally.

```dart
scene.update(1 / 60); // Manual update at 60 FPS.
scene.render(canvas); // Manual render (e.g. to a `PictureRecorder`).
scene.render(canvas, debug: true); // Manual render with debug rendering.
scene.destroy(); // All done, thanks.
```
