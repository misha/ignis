---
title: Motivation
description: Why Ignis exists when Flame already does.
lane: usage
category: essay
status: complete
related: [/concepts/building, /concepts/signals, /concepts/math]
---

## Why a New Engine

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

In Ignis, nodes *must* set themselves up synchronously. There isn't a `load` method: a node takes its arguments in its constructor and declares the rest of itself in [`build()`](/concepts/building), both of which run to completion before anything else touches the node. You can always use a node's methods and signals immediately after creating it, no queuing or remembering to `await loaded` necessary.

<Why>

  **Why can't `build()` be `async`?** Because everything downstream assumes a built node is finished. A mounted node is expected to be fully declared, and a rebuild is expected to replace the previous build outright. An `async` build would leave a half-declared node sitting in a live tree, updating and rendering, for an unbounded number of frames.

</Why>

The drawback is that assets *must* be loaded ahead of time. To compensate, Ignis ships with a highly configurable [preloading system](/systems/assets).

### Virtual Methods vs. Signals

In Flame, implementing behavior for special events (like collisions and gestures) usually requires extending a component and overriding a virtual method.

Virtual methods make it difficult to compose behavior and have no native faculty for handling multiple listeners. To resolve the issue, I wrote [`flame_fuse`](https://github.com/misha/flame_fuse), a library that enables composable behavior in Flame. Every Flame game I wrote in the last three years works using `flame_fuse`. (You may even see the beginnings of Ignis in that package!)

In Ignis, aside from `build()`, nodes receive engine information using [signals](/concepts/signals). Signals are explicit, accessible without subclasses, and natively support any number of listeners. If you can access the signal, you can watch it and you can emit it.

The net result is that the number of custom nodes you write in Ignis is much lower - usually just one per "thing" in your game. For example, a `PlayerNode` likely just uses a raw `SpriteNode`, `ColliderNode`, etc. by connecting directly to their signals.

<Why>

  **Why not `ChangeNotifier`?** `ChangeNotifier` is similar to `Signal`, but it was made for widgets, not nodes. `ChangeNotifier` comes with three drawbacks: poor performance, lack of N-argument typing, and a requirement to call `dispose`. Signals are fast, support specific argument counts, and do not require disposal.

</Why>

### `vector_math` vs. `ivector_math`

Flame uses `vector_math`, a popular, well-tested math library. Unfortunately, the API of `vector_math` is suboptimal from the perspective of control: it's very hard to tell when you are creating new objects or mutating them.

Ignis instead uses [`ivector_math`](/concepts/math), a reimplementation of `vector_math` that creates a syntactic gap between its mutable and immutable APIs. As a result, it's difficult to write code that accidentally mutates vectors and matrices - both in the engine itself, and in your game.

<Warning>

  While `ivector_math` was created specifically to make Ignis more safe and performant, it is less battle-tested and offers significantly fewer features compared to the original `vector_math`. However, I still think it's the better fit.

</Warning>
