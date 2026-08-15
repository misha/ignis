<p align="center">
  <img src="logo_light.png#gh-light-mode-only" alt="Light Mode Logo">
  <img src="logo_dark.png#gh-dark-mode-only" alt="Dark Mode Logo">
</p>

<p align="center">
  A Flutter game engine built on nodes and signals.
</p>

<p align="center">
  <a href="https://github.com/misha/ignis/actions/workflows/ci.yml" title="tests">
    <img src="https://github.com/misha/ignis/actions/workflows/ci.yml/badge.svg"/>
  </a>
</p>

<p align="center">
  What is this? See <a href="#motivation">Motivation</a>.
</p>

<div align="center">
  <i>Logo art by <a href="https://mewyn.itch.io/">Mewyn</a>.</i>
</div>

- [Features](#features)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Concepts](#concepts)
  - [Nodes](#concept-nodes)
  - [Scenes](#concept-scenes)
  - [Signals](#concept-signals)
  - [Time](#concept-time)
  - [Math](#concept-math)
- [Nodes](#nodes)
- [Layout](#layout)
- [Effects](#effects)
- [Sprites](#sprites)
- [Palettes](#palettes)
- [Collision Detection](#collision-detection)
- [Inputs](#inputs)
- [Assets](#assets)
- [Live Assets](#live-assets)
- [Globals](#globals)
- [Dependency Injection](#dependency-injection)
- [Motivation](#motivation)
- [Differences from Flame](#differences-from-flame)
- [Roadmap](#roadmap)
- [License](#license)

## Features

- **Embrace composition.** Everything - sprites, shapes, text, colliders, effects - is a `Node`. Compose behavior and graphics by building trees.
- **Completely synchronous.** Nodes are instantiated, updated, and rendered in a completely synchronous loop. Errors are reported at the source.
- **Signals, not callbacks.** The `Signal`, a lightweight event emitter, powers everything from animations to collisions.
- **Embedded in Flutter.** Any node can be rendered in the widget tree via `SceneWidget`. Ignis runs wherever Flutter runs (I think).
- **Flutter's layout, on nodes.** `RowNode`, `ColumnNode`, and `BoxNode` behave like the widgets you already know.
- **Asset preloading.** `Preload` concurrently loads assets with `Loader`s for images, data, or custom resource types.
- **Live assets.** When developing on the host machine, `LiveAssetBundle` instantly reloads assets into running scenes, no hot reload necessary.

## Quick Start

Mount any `Node` to a `Scene`, then pass it to a `SceneWidget`.

```dart
import 'package:flutter/material.dart';
import 'package:ignis/ignis.dart';

class GameNode extends TransformNode {
  final player = ShapeNode(
    shape: Shape.circle(16),
    anchor: Anchor.center,
    paint: Paint()..color = Colors.orange,
  );

  GameNode() {
    add(player);
  }

  @override
  void tick(double dt) {
    player.position.x += 40 * dt;
  }
}

void main() {
  final game = GameNode();
  final scene = game.mount();
  runApp(MaterialApp(home: SceneWidget(scene)));
}
```

## Concepts

### Concept: Nodes

`Node` is the primitive of Ignis.

A node is set up just once, in its constructor. Node constructors can wire up children, subscribe to signals, retrieve cached assets - there are no restrictions.

Nodes can override `tick(dt)` to run per-frame logic and `render(canvas)` to use the canvas. These are called in separate passes, once per frame, by the game loop.

Node comes with two signals, `onMount` and `onUnmount`, which are emitted when that instance enters and exits a scene. Other nodes expose additional signals based on their specific purpose.

Any node can have children, which are sorted by `priority`. Priority dictates the order in which they are updated and rendered.

```dart
class Ship extends TransformNode {
  final sprite = SpriteNode(sheet: Spritesheet.asset('ship.png'));
  final thruster = ShipThrusterNode(); // Your own `Node` subclass.
  final velocity = Vector2(10, 0);
  
  Ship() {
    addAll([sprite, thruster]);
  }

  @override
  void tick(double dt) {
    position.addScaled(velocity, dt);
  }
}
```

For a complete list of available nodes, see [Nodes](#nodes).

### Concept: Scenes

Any node can be mounted to create a `Scene`. Scenes wrap a tree of nodes with a size, and offer methods to manipulate the entire node tree effectively. A scene is also required when using a `SceneWidget`, which lets Flutter drive the engine.

```dart
final game = GameNode();
final scene = game.mount();
final widget = SceneWidget(scene); // Embed the scene in Flutter.
```

`SceneWidget` acts as a controller for the scene in Flutter. You can control rendering and the underlying game loop using its parameters:

```dart
final widget = SceneWidget(
  scene,
  paused: true, // Start the scene paused.
  debug: true,  // Enable debug rendering.
);
```

Scenes can also be driven completely manually. In fact, this is how much of Ignis is tested internally.

```dart
scene.update(1 / 60); // Manual update at 60 FPS.
scene.render(canvas); // Manual render (e.g. to a `PictureRecorder`).
scene.render(canvas, debug: true); // Manual render with debug rendering.
```

### Concept: Signals

Nodes communicate time-sensitive events through `Signal`, a lightweight message emitter.

> :robot: **Why "signal"?** The name is taken from the parallel concept in Godot.

By convention, signals are prefixed with `on` so subscriptions read naturally in node constructors.

```dart
// Declare a signal with 1 parameter. There are Signal0, Signal1, ...
final onCollision = Signal1<ColliderNode>();

// Call a signal with a function argument to watch it.
final unwatch = onCollision((other) => print('Hit $other!'));

// Sends a type-safe message to all watchers.
onCollision.emit(someCollider);

// Stop watching the signal.
unwatch();
```

Although nodes are driven by signals, `Signal` is a standalone utility class and may be used anywhere. Notably, signals can easily be used to implement communication between your Flutter app and your Ignis game. Here's an example integration using [`flutter_hooks`](https://pub.dev/packages/flutter_hooks).

```dart
/// Calls [handle] whenever [signal] is emitted.
void useSignal0(Signal0 signal, void Function() handle) {
  useEffect(() {
    return signal(handle);
  }, [signal, handle]);
}
```

> :warning: When using signals in nodes, prefer to listen to signals that belong to your children. By doing so, the signals will not leak when the node goes out of use. However, when watching global signals or signals belonging to parent and sibling nodes, remember to `unwatch` them or the signal will leak a reference to the watching node. In practice, `unwatch` is almost never required.

### Concept: Time

In Ignis, the unit of time is **seconds**.

For example, nodes receive a tick each frame of the game loop, along with the amount of time that passed as `dt`:

```dart
void tick(double dt) {
  // `dt` seconds elapsed this frame.
  // This is usually quite small, e.g. 0.01666 at 60 FPS.
}
```

All objects that accept an interval or duration are also expressed in seconds.

```dart
// Triggers after 200 milliseconds.
final timer = TimerNode(interval: 0.2);

// Progresses an effect over the course of 1.5 seconds.
final controller = EffectController.duration(1.5);
```

### Concept: Math

Math types such as `Vector2`, `Matrix3`, and `Aabb2` come from Ignis' companion [`ivector_math`](https://pub.dev/packages/ivector_math) package.

Unlike `vector_math`, every `ivector_math` type comes as a pair: an immutable base type (`Vector2`, `Matrix3`, `Aabb2`) with no mutating method of any kind, and a mutable sibling (`MVector2`, `MMatrix3`, `MAabb2`) that always `implements` it.

A value typed `Vector2` is simply a fact; nothing is capable of changing it. Similarly, a value typed `MVector2` can always be mutated by whoever holds it, no ceremony required.

```dart
final position = MVector2.zero();
position.addScaled(velocity, dt);
```

Because `MVector2` implements `Vector2`, a node can hold its own state as an `MVector2` internally while exposing it publicly as `Vector2`. This lets you control when those values are changed, if ever, at no performance cost.

Although it was developed with Ignis in mind, `ivector_math` is otherwise generally applicable.

> :warning: Ignis exports `ivector_math`; do not add it to your `dependencies`.

## Nodes

Ignis comes with the following nodes.

| Node                     | Purpose                                                          | Signals                              |
|--------------------------|------------------------------------------------------------------|--------------------------------------|
| `Node`                   | Base node specifying `enabled`, `priority`, and `children`.      | `onMount`, `onUnmount`               |
| `CollisionDetectionNode` | Holds a `CollisionDetection` arena.                              | -                                    |
| `ColliderNode`           | Registers its `Shape` with the nearest `CollisionDetectionNode`. | `onCollisionStart`, `onCollisionEnd` |
| `EffectNode`             | Base node for time-driven effects. See [Effects](#effects).      | `onFinish`                           |
| `FpsNode`                | Tracks a rolling-window average frame rate in `fps`.             | `onUpdate`                           |
| `InputNode`              | Base hit area for gestures. See [Inputs](#inputs).               | -                                    |
| `LayoutNode`             | Base node for laid-out nodes. See [Layout](#layout).             | -                                    |
| `PaintedNode`            | Base node using `Paint`. See [Palettes](#palettes).              | -                                    |
| `ShapeNode`              | Draws a `Shape`.                                                 | -                                    |
| `SizedNode`              | Base node with a size, used for shapes, sprites, and more.       | -                                    |
| `SpriteNode`             | Animates a `Spritesheet`. See [Sprites](#sprites).               | `onFrame`, `onLoop`, `onFinish`      |
| `TextNode`               | Draws text with `TextPainter`, wrapping to fit.                  | -                                    |
| `TimerNode`              | Tracks time to power its signal.                                 | `onTrigger`                          |
| `TransformNode`          | Base spatial node with a `position`, `scale`, and `angle`.       | -                                    |

## Layout

`LayoutNode` is a node whose size is decided by its parent rather than by its own content.

Ignis lays these out the way Flutter lays out widgets. In general, if you know the widget, you know the node.

Ignis comes with the following layout nodes.

| Layout Node  | Purpose                                           | Flutter     |
|--------------|---------------------------------------------------|-------------|
| `BoxNode`    | Sizes a region and places its children inside it. | `Container` |
| `FlexNode`   | Lays children out along a given `Axis`.           | `Flex`      |
| `RowNode`    | Lays children out horizontally.                   | `Row`       |
| `ColumnNode` | Lays children out vertically.                     | `Column`    |

The code below constructs a HUD entirely from layout nodes. (It is modestly contrived to show off as many parameters as possible.)

```dart
final hud = ColumnNode(
  mainAxisSize: .min,
  crossAxisAlignment: .stretch,
  spacing: 6,
  children: [
    RowNode(
      mainAxisAlignment: .spaceBetween,
      children: [
        TextNode(text: 'Floor 7'),
        TextNode(text: '1200'),
      ],
    ),
    BoxNode(
      height: 10,
      padding: .all(2),
      alignment: .centerLeft,
      children: [
        ShapeNode(
          shape: .rectangle(Vector2(48, 6)),
          paint: Paint()..color = const Color(0xFFC0FFEE),
        ),
      ],
    ),
  ],
);
```

> :warning: Layout only flows from a layout node to its direct children. Put a plain node in between and the layout node underneath it starts over, sizing itself against the scene.

### Ignis-Flutter Cheatsheet

Many Flutter layout features can be expressed in Ignis nodes. The table below spells out some of the more common type translations.

| Flutter          | Ignis                                        |
|------------------|----------------------------------------------|
| `Align`          | `BoxNode`, set an `alignment`                |
| `Center`         | `BoxNode`, set `alignment` to `.center`      |
| `Padding`        | `BoxNode`, set a `padding`                   |
| `SizedBox`       | `BoxNode`, set a `width` and/or `height`     |
| `Stack`          | `BoxNode`, with more than one child          |
| `Expanded`       | Any layout node, set `flex` to `.expanded()` |
| `Flexible`       | Any layout node, set `flex` to `.flexible()` |
| `Spacer`         | `BoxNode`, set `flex` to `.expanded()`       |
| `Text`           | `TextNode`                                   |
| `Alignment`      | `Anchor`                                     |
| `BoxConstraints` | `LayoutConstraints`                          |

## Effects

`EffectNode`, called simply an *effect* in the documentation, is a node with a notion of being "finished".

Most effects extend `ControlledEffect`, exposing a proper `onProgress` signal from 0 (start) to 1 (finish) as their `EffectController` advances. Meanwhile, higher-order effects tend to extend `EffectNode` directly.

Ignis comes with the following effects.

| Effect                     | Purpose                                                       |
|----------------------------|---------------------------------------------------------------|
| `AnchorEffect`             | Mutates the anchor of a `SizedNode` over time.                |
| `ColorFilterOpacityEffect` | Given a `Paint`, mutates a `ColorFilter`'s alpha over time.   |
| `ColorOpacityEffect`       | Given a `Paint`, mutates the color's alpha channel over time. |
| `CombinedEffect`           | An effect that finished when all its sub-effects finish.      |
| `ControlledEffect`         | Base effect for effects that use an `EffectController`.       |
| `MoveEffect`               | Mutates the position of a `TransformNode` over time.          |
| `RotateEffect`             | Mutates the angle of a `TransformNode` over time.             |
| `ScaleEffect`              | Mutates the scale of a `TransformNode` over time.             |
| `SequentialEffect`         | An effect that advances its sub-effects serially.             |

Specific effects drop their `*Node` suffix and are simply called `*Effect`.

Effects that operate on `Paint` always indicate the specific property *of* `Paint` they operate on. For example, `ColorOpacityEffect` and `ColorFilterOpacityEffect` both animate the opacity of a `Paint`, but the mechanism used differs: one modifies `color`, the other sets the `colorFilter` property.

### Effect Controllers

The progress over time of any particular `ControlledEffect` is determined by its `EffectController`.

> :fire: The concept of an *effect controller*, like many ideas in Ignis, comes directly from Flame. If you've used Flame's `EffectController`, you should be quite comfortable!

`EffectController` is composable: there's no single monolithic constructor, only a handful of small controllers you chain together with a `SequenceEffectController`. The code below creates a controller that waits 500 milliseconds, then advances `progress` linearly from 0 to 1 over the next 1500 milliseconds.

```dart
final controller = SequenceEffectController([
  OnceEffectController(WaitEffectController(0.5)),
  DurationEffectController(1.5),
]);
```

Ignis comes with the following effect controllers.

| Effect Controller           | Purpose                                              |
|-----------------------------|------------------------------------------------------|
| `DurationEffectController`  | Progresses over a duration, shaped by a `Curve`.     |
| `InfiniteEffectController`  | Repeats its child forever.                           |
| `OnceEffectController`      | Runs its child once; ignored after that.             |
| `RepeatEffectController`    | Repeats its child a fixed number of times.           |
| `RoundtripEffectController` | Runs its child forward, then back down to its start. |
| `SequenceEffectController`  | Runs controllers one after another.                  |
| `WaitEffectController`      | Holds progress at 1 for a duration.                  |

Common controllers have a dot-shorthand constructor. Use it to make controller trees legible at a glance. The example from earlier could more succinctly be written:

```dart
EffectController controller = .sequence([
  .once(.wait(0.5)),
  .duration(1.5),
]);
```

## Sprites

`SpriteNode` draws frames from one or more `Spritesheet`s, optionally animating between them over time.

The code below creates a sprite from a spritesheet of 32x32 pixel tiles, animated at 12 frames per second (FPS).

```dart
final sprite = SpriteNode(
  sheet: Spritesheet.asset('assets/ship.png', size: .all(32)), 
  fps: 12, 
  loop: true,
);
```

Call `play` to begin animating from a specific row and column in the spritesheet.

```dart
// Animates the second row.
sprite.play(row: 1);
```

> :warning: `SpriteNode` can only play animations on the same row.

It's also possible to combine multiple spritesheets via `SpriteNode.split`. This is particularly useful for swapping animation sets, like an idle sheet and a running sheet, while keeping assets modular.

```dart
final sprite = SpriteNode.split(
  sheets: [
    .asset('assets/player/idle.png', size: .all(32)),
    .asset('assets/player/running.png', size: .all(32)), 
  ], 
  fps: 12,
  loop: true,
);

// Animates the third row of the running spritesheet.
sprite.play(sheet: 1, row: 2);
```

## Palettes

Sprites and shapes implement `PaintedNode`, giving them access to a `Palette`. A *palette* is an ordered collection of named `Paint`s, letting a single node draw several times each `render` without additional code.

> :fire: Ignis' `Palette` is inspired by Flame's `HasPaint` mixin.

Every palette starts with one default paint, accessible via `paint` on either the palette or its owning node.

```dart
final shape = ShapeNode(
  shape: .circle(16),
  paint: Paint()..color = Colors.orange,
);

// Painted nodes expose the default paint via their palette.
assert(identical(shape.paint, shape.palette.paint));
```

Palettes begin with one paint by default, but you can easily register additional paints. The code below registers a `shadow` paint that draws behind the default paint at a slight offset.

```dart
// Register a new paint by name.
palette.add(
  PaletteEntry(
    // The paint's unique name.
    'shadow',

    // The actual paint to draw with.
    Paint()..color = Colors.black54,

    // The offset at which to draw with this paint.
    // Defaults to 0.
    offset: .all(4),

    // The order in which to draw with this paint.
    // Defaults to 0.
    priority: -1,

    // Whether or not to draw with this paint.
    // Defaults to true.
    enabled: true, 
  ),
);

// Retrieve the newly added paint.
final shadowPaint = palette['shadow'];

// Or retrieve the entire entry to update enabled, priority, etc.
final shadowEntry = palette.entry('shadow');
shadowEntry.enabled = false; // No shadow for now.

// When you're done with the paint, remove it by name as well.
palette.remove('shadow');
```

> :warning: Entry names must be unique within a palette. Additionally, a `PaletteEntry` may only belong to one `Palette` at a time.

It's quite common to access the palette when creating effects. The code below fades out the `shadow` paint linearly over 500 milliseconds.

```dart
add(
  ColorOpacityEffect.fadeOut(
    paint: palette['shadow'], 
    controller: .duration(0.5),
    cleanup: true,
  ),
);
```

## Collision Detection

Collisions work using two nodes, `CollisionDetectionNode` and `ColliderNode`.

`CollisionDetectionNode` sets up an actual collision detection arena. Whenever a `ColliderNode` is added to a scene, it finds the closest `CollisionDetectionNode` and registers itself.

```dart
final cd = CollisionDetectionNode();
final player = ColliderNode(shape: .circle(16));
final wall = ColliderNode(shape: .rectangle(.new(32, 200)));
cd.addAll([player, wall]);

player.onCollisionStart((other) {
  print('Hit $other!');
});
```

`ColliderNode` also supports specifying two bitmasks, `layer` and `mask`, to exclude certain collisions from consideration. `layer` indicates the physics layers the collider exists on, while `mask` indicates which physics layers it collides with. A pair only reports a collision to a side whose `mask` intersects the other's `layer`.

> :warning: While `layer` and `mask` are defined as integers, they should be treated as bitmasks. Each position in the integer is a separate physics layer. That also means Ignis only supports up to 32 collision detection layers. By default, `layer` and `mask` are -1 (all bits are 1), letting all colliders interact.

The code below adjusts the previous example to exclude wall-wall collisions altogether, greatly improving collision detection performance and removing the need to handle those cases in your code.

```dart
const TERRAIN_LAYER = 1 << 0;
const UNIT_LAYER = 1 << 1;

wall
  ..layer = TERRAIN_LAYER;

player
  ..layer = UNIT_LAYER
  ..mask = TERRAIN_LAYER | UNIT_LAYER;
```

> :robot: **Why "layer" and "mask"?** These names come from Godot's collision system.

### Limitations in Collision Detection

At this time, the collision detection implementation only supports `Shape` and does not return collision points or depth. In exchange, it is quite fast!

Expanding the capabilities and usefulness of collision detection in Ignis while maintaining solid performance is a focus of ongoing development. Specifically, a general `Polygon` shape is well within the engine's scope.

## Inputs

`InputNode` is a hit area that recognizes pointer gestures by delegating to Flutter's own gesture recognizers. It has its own shape too, so it's free to cover an area larger or smaller than whatever it's representing.

A node wanting more than one gesture just adds more input nodes. When multiple input nodes overlap, `priority` decides who's tried first. An event a node doesn't apply to, such as `HoverInput` receiving a tap, always falls through to the next input node. Once a node *does* claim an event, the search stops there unless its `behavior` is `HitBehavior.translucent`.

Ignis comes with the following inputs.

| Input        | Purpose             | Signals                                                    |
|--------------|---------------------|------------------------------------------------------------|
| `TapInput`   | Recognizes taps.    | `onTapDown`, `onTapUp`, `onTap`, `onTapCancel`             |
| `DragInput`  | Recognizes drags.   | `onDragStart`, `onDragUpdate`, `onDragEnd`, `onDragCancel` |
| `HoverInput` | Tracks mouse hover. | `onHoverEnter`, `onHoverExit`                              |

The code below is a simple way to implement the common drag-and-drop pattern.

```dart
final piece = ShapeNode(shape: .circle(16));
final drag = DragInput(shape: piece.shape);
piece.add(drag);

drag.onDragUpdate((event) {
  piece.position.add(event.delta);
});
```

## Assets

In Ignis, all assets must be loaded to the `Cache` in order to be accessible in nodes. The entrypoint for loading is `Preload`.

A preload is two separate things: a registry of pluggable `Loader`s that decide *how* an asset is read, and a `load` call that names *which* assets to read. Ignis ships with a few loaders for common asset types like images and JSON, but it's easy to write your own, too.

```dart
// Register the loaders once. Every asset is offered to each of them, and their
// own filters decide which ones they actually apply to.
Ignis.preload
  
  // Load images, detected by extension.
  ..register(
    Loader.image()
      ..extensions(['png', 'jpg', 'gif']),
  )
  
  // Load the game's JSON level files, detected by prefix and extension.
  ..register(
    Loader.json()
      ..prefix('assets/levels/')
      ..extensions(['json']),
  );

// Load everything in the bundle's `AssetManifest`. Returns a `PreloadRequest` future.
await Ignis.preload.load(manifest: true);

// Retrieve assets by looking into the cache.
final level1 = Ignis.cache.retrieve<Map>('assets/levels/level1.json');
```

Loading is not one-time. The same registry serves a game's startup load and every load after it, so a level transition just names the assets it needs:

```dart
await Ignis.preload.load(paths: ['assets/levels/level2.json']);
```

Preload calls may overlap freely. Internally, it uses a worker pool that bounds its concurrency and prevents loading from overloading the application.

### Animating a Preload

A `PreloadRequest` is a `ChangeNotifier` that tracks `total`, `completed`, and `progress`, so a loading screen can animate off it directly.

Below is a common pattern using [`riverpod`](https://pub.dev/packages/riverpod) and [`flutter_hooks`](https://pub.dev/packages/flutter_hooks) which kicks off a game's startup load, then watches it from a loading page:

```dart
final preloadPod = Provider((ref) {
  final request = Ignis.preload.load(manifest: true);
  ref.onDispose(request.dispose);
  return request;
});

class LoadingPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final request = useListenable(ref.watch(preloadPod));
    final progress = request.progress;

    useEffect(() {
      if (progress >= 1) {
        // Launch the game!
      }
    }, [progress]);

    return Scaffold(
      body: Column(
        children: [
          Text('Loading...'),
          LinearProgressIndicator(value: progress),
        ]
      ),
    );
  }
}
```

For a load with nothing to keep around, `Preload.run` builds a throwaway preload and releases everything once it finishes.

```dart
await Preload.run(
  loaders: [Loader.image()..extensions(['png'])],
  manifest: true,
);
```

> :question: **Why preload at all?** Since nodes are synchronous, they cannot retrieve assets asynchronously. But even if they could, what do you render while the asset is loading? Rather than resolving this concern with a complex API, Ignis protects the visual fidelity of your game by simply requiring preloading, and making it easy to configure and animate, too.

> :warning: A `PreloadRequest` is a `ChangeNotifier`, so `dispose` it once you are done with it. `Preload.run` is the exception: it owns the whole lifetime, and disposes the request for you.

## Live Assets

If you develop locally, Ignis provides a `LiveAssetBundle` to instantly update assets in live scenes during development.

For example, you can save an image in your art program and the running scene will pick it up on the next frame, no hot reload involved. The bundle works by detecting updated paths and pushing them to `Ignis.preload`, reusing the exact same asset pipeline as your production code.

`LiveAssetBundle` is optional and opt-in. Install it as `Ignis.bundle` when your application starts:

```dart
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Live reloading feeds changed assets back through `Ignis.preload`,
  // so the loaders have to be registered there.
  Ignis.preload.register(Loader.image()..extensions(['png']));

  final live = LiveAssetBundle();
  Ignis.bundle = live;
  await live.start(); // Make sure to start it!
  
  // Preload as usual.
  await Ignis.preload.load(manifest: true);

  runApp(MyGameApp());
}
```

`LiveAssetBundle` reads the pubspec's `assets` manifest to decide what to watch, exactly how Flutter builds your bundle. Changes are served from the project directory rather than the compiled bundle, so a simple file save is sufficient to trigger an update.

Invalidation follows dependencies. Replacing an image evicts every `Spritesheet` cut from it, and any `SpriteNode` drawing that sheet re-resolves on its next frame, resizing itself if the new art has different dimensions.

By default the project root is the running process's working directory. Point it elsewhere when that isn't your project:

```dart
final live = LiveAssetBundle(root: '/path/to/project');
```

`LiveAssetBundle` only works when `kDebugMode` is enabled, so shipping it is harmless. In release and web builds, every asset load goes safely through to the base bundle.

> :warning: **Live assets only work on the machine hosting the project.** The bundle reads files straight off disk with `dart:io`, so it needs the running app and the project source to share a filesystem. That means desktop and the local simulator only.

## Globals

The `Ignis` namespace holds the global `AssetBundle`, `Cache`, and `Preload`. Most games will only touch `Ignis.preload`, to register their loaders.

Every preload reads from `Ignis.bundle` into `Ignis.cache`. Similarly, `Spritesheet` retrieves from `Ignis.cache`.

```dart
// The following spritesheets are equivalent:
final sheet1 = Spritesheet.asset('assets/ship.png');
final sheet2 = Spritesheet(Ignis.cache.retrieve('assets/ship.png'));
```

> :warning: `Ignis.cache`, `Ignis.bundle`, and `Ignis.preload` are mutable static members, not constants. Swap them out for tests or when running multiple, isolated games in one application.

## Dependency Injection

Nodes come integrated with a type-based dependency injection (DI) system. Any node can `provide` a value to its own subtree, and any node can `read` the nearest match back by type.

Since `read` access its tree, it is not available until mount. Use it in combinations with `onMount`, inside `tick`, or in response to signals that occur when the node is in use, like collisions and inputs.

```dart
class GameNode extends Node {
  GameNode() {
    provide(Settings(volume: 0.8));
  }
}

class PlayerNode extends TransformNode {
  @override
  void tick(double dt) {
    final settings = read<Settings>();
    // ...
  }
}
```

For optional dependencies, `readOrNull` behaves identically but returns null instead of throwing when nothing was provided.

> :warning: Note that `read` and `readOrNull` are *not* reactive. The first read of that type always caches the result - null or otherwise - so a later `provide` won't be picked up.

## Motivation

Why does Ignis exist?

I, [@misha](https://github.com/misha), have been making [games](https://misha.itch.io/) using [Flame](https://flame-engine.org/) for many years. In late 2025, I decided to do that full time as an indie game developer.

Flame has been my engine of choice for three reasons.

  - **Dart.** I am very picky about programming languages, but I *love* writing Dart. I know no language that comes even close. Flame uses Dart. Fantastic.
  - **Flutter.** I have a strong, personal conviction that most games are more UI/UX than game graphics - it's the menus that determine ratings (\*cough\*, looking at you, *Civilization 7*). But UI/UX is fundamentally different from game graphics, and deserves a separate framework. Flame lives alongside Flutter, a UI/UX framework with which I have extensive professional experience shipping dozens of apps over the last decade.
  - **Unopinionated.** Look through Flame's documentation. You'll find that each part of Flame solves a different, specific problem. If you don't have the problem, that solution just *gets out of your way*. Have you ever tried Unity? Yeah. This is the opposite of that.

On a whim, I began experimenting with [Godot](https://godotengine.org/) last year. I was incredibly surprised at how intuitive the node hierarchy, signals, and asset management were. Unfortunately, I quickly fell out of the honeymoon phase trying to develop user interfaces and safe, ergonomic abstractions in GDScript. The programming experience provided by Dart and Flutter is worlds apart.

When I eventually came home to Flame, I realized I missed Godot's mental model of `Node`s and `Signal`s. Initially, I wrote Ignis on top of Flame's low-level `Game` class, with a `Node` hierarchy completely replacing `Component`. But soon I noticed there wasn't that much I needed from Flame, and simply adopted the remaining classes into the codebase. `Anchor`, `RenderLoop`, `SceneRenderBox`, `SceneWidget`, some of `TransformNode`, and a plethora of bits and bobs throughout Ignis can trace their lineage directly to Flame.

Ignis literally would not exist without Flame. Meanwhile, the new abstractions are my (flexible!) interpretation of Godot's primitives. I chose the name "ignis" because it means "flame" in Latin, yet has the same foreign-sounding mouthfeel as "godot".

Until now, Flame has been the *only* reliable, unopinionated option for 2D game development in Flutter. I'm hoping Ignis can be a second.

## Differences from Flame

Ignis makes several fundamentally different architectural decisions compared to [Flame](https://flame-engine.org/). This section hopes to explain these trade-offs and how they affect the usage of the engine.

### Synchronous vs. Asynchronous

In Flame, any component can declare an `async` loading method. While this makes it easy to load assets dynamically, in practice it creates a confusing gap: you can't safely manipulate a component until it's done loading!

In Ignis, nodes *must* be loaded synchronously. There isn't a `load` method because nodes are expected to set themselves up in their constructors. You can always use a node's methods and signals immediately after creating it, no queuing or remembering to `await loaded` necessary.

> :question: **Why load in the constructor?** Constructors are the only code location that must be synchronous. Having any kind of virtual `load` method, even a `void` one, would open it to being overridden with `async` and breaking the engine's invariants.

The drawback is that assets *must* be loaded ahead of time. To compensate, Ignis ships with a highly configurable preloading system.

### Virtual Methods vs. Signals

In Flame, implementing behavior for special events (like collisions and gestures) usually requires extending a component and overriding a virtual method.

Virtual methods make it difficult to compose behavior and have no native faculty for handling multiple listeners. To resolve the issue, I wrote [`flame_fuse`](https://github.com/misha/flame_fuse), a library that enables composable behavior in Flame. Every Flame game I wrote in the last three years works using `flame_fuse`. (You may even see the beginnings of Ignis in that package!)

In Ignis, aside from `tick(dt)` and `render(canvas)`, nodes receive engine information using signals. Signals are explicit, accessible without subclasses, and natively support any number of listeners. If you can access the signal, you can watch it and you can emit it.

The net result is that the number of custom nodes you write in Ignis is much lower - usually just one per "thing" in your game. For example, a `PlayerNode` likely just uses a raw `SpriteNode`, `ColliderNode`, etc. by connecting directly to their signals.

> :question: **Why not `ChangeNotifier`?** `ChangeNotifier` is similar to `Signal`, but it was made for widgets, not nodes. `ChangeNotifier` comes with three drawbacks: poor performance, lack of N-argument typing, and a requirement to call `dispose`. Signals are fast, support specific argument counts, and do not require disposal.

### `vector_math` vs. `ivector_math`

Flame uses `vector_math`, a popular, well-tested math library. Unfortunately, the API of `vector_math` is suboptimal from the perspective of control: it's very hard to tell when you are creating new objects or mutating them.

Ignis instead uses `ivector_math`, a reimplementation of `vector_math` that creates a syntactic gap between its mutable and immutable APIs. As a result, it's difficult to write code that accidentally mutates vectors and matrices - both in the engine itself, and in your game.

> :warning: While `ivector_math` was created specifically to make Ignis more safe and performant, it is less battle-tested and offers significantly fewer features compared to the original `vector_math`. However, I still think it's the better fit.

## Roadmap

Until `1.0.0`, Ignis will change frequently and dramatically.

I'm currently working on the following:

- Camera
- Audio
- Particles
- Debugging tools
- More nodes
- More effects
- More examples

## License

[MIT](LICENSE)
