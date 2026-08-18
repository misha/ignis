---
title: Motivation
description: Why Ignis exists when Flame already does.
lane: usage
category: essay
status: complete
related: [/concepts/nodes, /concepts/signals, /concepts/math]
---

## Why a New Engine

I, [@misha](https://github.com/misha), have been making [games](https://misha.itch.io/) using [Flame](https://flame-engine.org/) for many years. In late 2025, I decided to do that full time as an indie game developer.

Flame has been my engine of choice for three reasons.

  - **Dart.** I am very picky about programming languages, but I *love* writing Dart. I know no language that comes even close. Flame uses Dart. Fantastic.
  - **Flutter.** I have a strong, personal conviction that most games are more UI/UX than game graphics - it's the menus that determine ratings (\*cough\*, looking at you, *Civilization 7*). But UI/UX is fundamentally different from game graphics, and deserves a separate framework. Flame lives alongside Flutter, a UI/UX framework with which I have extensive professional experience shipping dozens of apps over the last decade.
  - **Unopinionated.** Look through Flame's documentation. You'll find that each part of Flame solves a different, specific problem. If you don't have the problem, that solution just *gets out of your way*. Have you ever tried Unity? Yeah. This is the opposite of that.

On a whim, I began experimenting with [Godot](https://godotengine.org/) last year. I was incredibly surprised at how intuitive the node hierarchy, signals, and asset management were. Unfortunately, I quickly fell out of the honeymoon phase trying to develop user interfaces and safe, ergonomic abstractions in GDScript. The programming experience provided by Dart and Flutter is worlds apart.

When I eventually came home to Flame, I realized I missed Godot's mental model of `Node`s and `Signal`s. Initially, I wrote Ignis on top of Flame's low-level `Game` class, with a `Node` hierarchy completely replacing `Component`. But soon I noticed there wasn't that much I needed from Flame, and simply adopted the remaining classes. Many of the core abstractions and Flutter-related bits can trace their lineage directly to Flame.

Ignis would not exist without Flame, while the new abstractions are my (creative) interpretation of Godot's primitives. I chose the name "ignis" because it means "flame" in Latin, yet has the same foreign-sounding mouthfeel as "godot".

Until now, Flame has been the only reliable, unopinionated option for 2D game development in Flutter. I'm hoping Ignis can be a second.

## Locality of Behavior

Ignis commits to a single driving principle from which its entire architecture emerges. That principle is *locality of behavior*, a property of source code referring to its ability to keep related code physically close together.

Consider the following `Ball`, implemented with a hypothetical game engine that runs using virtual method overrides.

```dart
class Ball extends GameObject {
  final position = Vector2.zero();
  final velocity = Vector2.zero();
  final paint = Paint()..color = Colors.green;
  var collisions = 0;

  @override
  void update(double dt) {
    position += velocity * dt;
  }

  @override
  void onCollisionStart(GameObject other) {
    collisions += 1;
    paint.color = Colors.red;

    if (other is Wall) {
      velocity.reflect(other.normal);
    }
  }

  @override
  void onCollisionEnd(GameObject other) {
    collisions -= 1;

    if (collisions == 0) {
      paint.color = Colors.green;
    }
  }
}
```

Our `Ball` has two major concerns:

- It manages a `velocity`, using it to increment `position` and reflecting it off colliding walls.
- It manages a `paint`, turning it red when there are active collisions, and green otherwise.

With this API, it is not possible to write all the code related to `velocity` or all the code related to `paint` in one contiguous region. The two concerns are **inevitably** interspersed. Imagine a complex object with fifty! It's spaghetti.

Now, let's consider a different game engine, one that accepts function closures instead of virtual method overrides. `Ball` would be refactored as follows:

```dart
class Ball extends GameObject {
  final position = Vector2.zero();
  final velocity = Vector2.zero();
  final paint = Paint()..color = Colors.green;
  var collisions = 0;

  @override
  void build() {
    // velocity concern

    onUpdate((double dt) {
      position += velocity * dt;
    });

    onCollisionStart((GameObject other) {
      if (other is Wall) {
        velocity.reflect(other.normal);
      }
    });

    // paint concern

    onCollisionStart((GameObject other) {
      collisions += 1;
      paint.color = Colors.red;
    });

    onCollisionEnd((GameObject other) {
      collisions -= 1;

      if (collisions == 0) {
        paint.color = Colors.green;
      }
    });
  }
}
```

The new API allows the programmer to define each concern in a single, contiguous region of the code. In short, locality of behavior is achieved.

## Differences from Flame

Ignis makes several fundamentally different architectural decisions compared to Flame. This section hopes to explain these trade-offs and how they affect the usage of the engine.

### Synchronous vs. Asynchronous

In Flame, any component can declare an `async` loading method. This makes it possible to load assets dynamically, as components are added to the game.

In Ignis, nodes *must* set themselves up synchronously. A synchronous node is easier to think about; if you've added it to the scene, it's now live, no `await` necessary. It is also no longer possible to have frames where some nodes may have been loaded while others have not, asserting the visual fidelity of the game from the very first render.

To compensate, Ignis ships with a highly configurable [preloading system](/systems/assets). That same system *also* enables live assets, as the engine is now aware of how your application loads its assets, continuing the commitment to live reload in general.

### Virtual Methods vs. Signals

In Flame, implementing behavior for special events (like collisions and gestures) usually requires extending a component and overriding a virtual method.

In Ignis, nodes receive events using [signals](/concepts/signals). Signals are explicit, accessible without subclasses, and natively support any number of listeners. If you can access the signal, you can watch it and you can emit it.

As explained above, the primary motivation for this change is to permit a high degree of [locality of behavior](#locality-of-behavior) in the source code.

<Info>

I wrote and still maintain [`flame_fuse`](https://github.com/misha/flame_fuse), a library that enables locality of behavior in Flame. Every Flame game I wrote in the last three years uses `flame_fuse`. You may even see the beginnings of Ignis in that package!

</Info>

### `vector_math` vs. `ivector_math`

Flame uses `vector_math`, a popular, well-tested math library. Unfortunately, the API of `vector_math` is suboptimal from the perspective of control: it's very hard to tell when you are creating new objects or mutating them.

Ignis instead uses [`ivector_math`](/concepts/math), a reimplementation of `vector_math` that offers a mutable and an immutable version. As a result, every math type in the engine will tell whether or not a particular vector or matrix is mutable during static analysis.

<Warning>

  I wrote `ivector_math` specifically to make Ignis more safe and performant. It is significantly less battle-tested and offers fewer features compared to the original `vector_math`. However, I still think it's the better fit.

</Warning>
