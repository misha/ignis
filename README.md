[![Tests](https://github.com/misha/ignis/actions/workflows/ci.yml/badge.svg)](https://github.com/misha/ignis/actions/workflows/ci.yml)

# Ignis

Ignis is a Flutter game engine built around two primitives, nodes and signals.

What is this? See [Motivation](#motivation).

- [Features](#features)
- [Installation](#installation)
- [Quick start](#quick-start)
- [Concepts](#concepts)
  - [Nodes](#concept-nodes)
  - [Scenes](#concept-scenes)
  - [Signals](#concept-signals)
  - [Math](#concept-math)
- [Nodes](#nodes)
- [Effects](#effects)
- [Sprites](#sprites)
- [Collision Detection](#collision-detection)
- [Assets](#assets)
- [Globals](#globals)
- [Motivation](#motivation)
- [Differences from Flame](#differences-from-flame)
- [Roadmap](#roadmap)
- [License](#license)

## Features

- **Embrace composition.** Everything - sprites, shapes, text, colliders, effects - is a `Node`. Compose behavior and graphics by building trees.
- **Completely synchronous.** Nodes are instantiated, updated, and rendered in a completely synchronous loop. Errors are reported at the source.
- **Signals, not callbacks.** The `Signal`, a lightweight event emitter, powers everything from animations to collisions.
- **Embedded in Flutter.** Any node can be rendered in the widget tree via `SceneWidget`. Ignis runs wherever Flutter runs (I think).
- **Asset preloading.** `Preload` concurrently loads assets with `Loader`s for images, shaders, or custom resource types.

## Quick Start

Mount any `Node` to a `Scene`, then pass it to a `SceneWidget`.

```dart
import 'package:flutter/material.dart';
import 'package:ignis/ignis.dart';

class GameNode extends TransformNode {
  final player = ShapeNode(
    shape: Shape.circle,
    size: Vector2.all(32),
    anchor: Anchor.center,
    paint: Paint()..color = Colors.orange,
  );

  GameNode() {
    add(player);
  }

  @override
  void tick(double dt) {
    player.position.mutate().x += 40 * dt;
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
    position.mutate().addScaled(velocity, dt);
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

### Concept: Math

Math types such as `Vector2`, `Matrix3`, and `Aabb2` come from Ignis' companion [`ivector_math`](https://pub.dev/packages/ivector_math) package. `ivector_math` is a re-implementation of `vector_math` with additional semantics for controlled mutability. Although it is developed with Ignis in mind, `ivector_math` is otherwise generally applicable.

Unlike `vector_math`, types in `ivector_math` are immutable by default. In order to modify one, call `mutate()` to obtain a scoped, mutable view for in-place updates.

```dart
final position = Vector2.zero();
position.mutate().addScaled(velocity, dt);
```

> :warning: Ignis exports `ivector_math`; do not add it to your `dependencies`.

## Nodes

| Node                     | Purpose                                                                      | Signals                              |
|--------------------------|------------------------------------------------------------------------------|--------------------------------------|
| `Node`                   | Base node specifying `priority` and `children`.                              | `onMount`, `onUnmount`               |
| `CollisionDetectionNode` | Holds a `CollisionDetection` arena.                                          | -                                    |
| `ColliderNode`           | Registers its `Shape` with the nearest `CollisionDetectionNode`.             | `onCollisionStart`, `onCollisionEnd` |
| `EffectNode`             | Base node for time-driven effects; see [Effects](#effects).                  | `onStart`, `onProgress`, `onFinish`  |
| `FpsNode`                | Tracks a rolling-window average frame rate in `fps`.                         | -                                    |
| `ShapeNode`              | Draws a `Shape` with `Paint`.                                                | -                                    |
| `SpriteNode`             | Animates a `Spritesheet` with `Paint`; see [Sprites](#sprites).              | `onFrame`, `onLoop`, `onFinish`      |
| `TextNode`               | Draws text with `TextPainter`.                                               | -                                    |
| `TimerNode`              | Tracks time to power its signal.                                             | `onTrigger`                          |
| `TransformNode`          | Base spatial node with a `position`, `scale`, `angle`, `size`, and `anchor`. | -                                    |

## Effects

| Effect          | Purpose                                                       |
|-----------------|---------------------------------------------------------------|
| `MoveEffect`    | Mutates a `Vector2` towards a destination over time.          |
| `OpacityEffect` | Given a `Paint`, mutates the color's alpha channel over time. |

## Sprites

`SpriteNode` draws frames from one or more `Spritesheet`s, optionally animating between them over time.

The example below creates a spritesheet of 32x32 pixel tiles, animated at 12 frames per second (FPS).

> :warning: `SpriteNode` can only play animations on the same row.

```dart
final sheet = Spritesheet.asset('assets/ship.png', size: .all(32));
final sprite = SpriteNode(sheet: sheet, fps: 12, loop: true);
```

Call `play` to begin animating from a specific row and column in the spritesheet.

```dart
sprite.play(row: 1); // Animate the second row.
```

It's also possible to combine multiple spritesheets via `SpriteNode.split`. This is particularly useful for swapping animation sets, like an idle sheet and a running sheet, while keeping assets modular.

```dart
final idle = Spritesheet.asset('assets/player/idle.png', size: .all(32));
final running = Spritesheet.asset('assets/player/running.png', size: .all(32));
final sprite = SpriteNode.split(sheets: [idle, running], fps: 12);
sprite.play(sheet: 1, row: 2); // Animate the third row of the running spritesheet.
```

Check out the code documentation for complete details on `SpriteNode` parameters and signals.

## Collision Detection

Collisions work using two nodes, `CollisionDetectionNode` and `ColliderNode`.

`CollisionDetectionNode` sets up an actual collision detection arena. Whenever a `ColliderNode` is added to a scene, it finds the closest `CollisionDetectionNode` and registers itself.

```dart
final cd = CollisionDetectionNode();
final player = ColliderNode(shape: .circle, size: .all(32));
final wall = ColliderNode(shape: .rectangle, size: .new(32, 200));
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

At this time, the collision detection implementation only supports `Shape` (circles and rectangles) and does not return the collision points. In exchange, it is blindingly fast.

Expanding the capabilities and usefulness of collision detection in Ignis while maintaining solid performance is a focus of ongoing development. 

## Assets

In Ignis, all assets must be loaded to the `Cache` in order to be accessible in nodes. The entrypoint for loading is `Preload`.

A preload loads assets into a cache in parallel, driven by pluggable `Loader`s. Ignis ships with a few loaders for common asset types like images and shaders, but it's easy to write your own, too.

```dart
// Set up a new preload.
final preload = Preload();

// Load assets from the root bundle's `AssetManifest`.
preload.manifest(
  
  // Try each of these loaders for every asset found.
  Loader.multiple([
    
    // Load images, detected by extension.
    Loader.image()
      ..extensions(['png', 'jpg', 'gif']),
    
    // Load the game's JSON level files, detected by prefix and extension.
    Loader.json()
      ..prefix('assets/levels/')
      ..extensions(['json'])
  ])
);

// Returns a future indicates when the preload is done.
await preload.run();

// Retrieve assets by looking into the cache.
final level1 = Ignis.cache.retrieve<Map>('assets/levels/level1.json');
```

`Preload` is also a `ChangeNotifier` with fields that track loading progress. A typical implementation pattern is to declare a single `Preload`, then animate its loading in a widget.

Below is a common pattern using [`riverpod`](https://pub.dev/packages/riverpod) and [`flutter_hooks`](https://pub.dev/packages/flutter_hooks) which sets up a game's one-time `Preload`, then watches it from a loading page:

```dart
final preloadPod = Provider((ref) {
  return Preload().manifest(
    .multiple([
      .image()
        ..extensions(['png', 'jpg', 'gif']),
      .json()
        ..prefix('assets/levels/')
        ..extensions(['json']),
    ]),
  );
});

class LoadingPage extends HookConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final preload = useListenable(ref.watch(preloadPod));
    final progress = preload.progress;

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

> :question: **Why preload at all?** Since nodes are synchronous, they cannot retrieve assets asynchronously. But even if they could, what do you render while the asset is loading? Rather than resolving this concern with a complex API, Ignis protects the visual fidelity of your game by simply requiring preloading, and making it easy to configure and animate, too.

> :warning: For games with many assets, you may want to set up ad-hoc `Preload` objects based on the assets needed for the next level. In this situation, remember to `dispose` each `Preload` when finished to avoid leaking `ChangeNotifier` resources.

## Globals

The `Ignis` namespace holds the global instances of the `AssetBundle` and `Cache`. Most games will not need to modify them directly.

By default, `Preload` and `Spritesheet` automatically access `Ignis.cache` when storing and retrieving assets.

```dart
// The following preloads are equivalent:
final preload1 = Preload();
final preload2 = Preload(cache: Ignis.cache);

// The following spritesheets are equivalent:
final sheet1 = Spritesheet.asset('assets/ship.png');
final sheet2 = Spritesheet(Ignis.cache.retrieve('assets/ship.png'));
```

> :warning: `Ignis.cache` and `Ignis.bundle` are mutable static fields, not constants. Swap them out for tests or when running multiple, isolated games in one application.

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
- Collision details
- Audio
- Hit testing
- Gestures & input
- Particles
- Debugging tools
- More nodes
- More effects
- More examples

## License

[MIT](LICENSE)
