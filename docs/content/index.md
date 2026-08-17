---
title: Ignis
description: A Flutter game engine built on nodes and signals.
lane: usage
category: essay
status: partial
---

Ignis is a Flutter game engine built on nodes and signals.

These docs are under construction. They exist to do the one thing the README cannot: run.

<Info>

  Every demo on this site is a real Ignis scene compiled into the page, not a recording or a code sample. The prose and the engine share Dart state directly.

</Info>

## Features

- **Embrace composition.** Everything - sprites, shapes, text, colliders, effects - is a `Node`. Compose behavior and graphics by building trees.
- **Completely synchronous.** Nodes are instantiated, updated, and rendered in a completely synchronous loop. Errors are reported at the source.
- **Signals, not callbacks.** The `Signal`, a lightweight event emitter, powers everything from animations to collisions.
- **Embedded in Flutter.** Any node can be rendered in the widget tree via `SceneWidget`. Ignis runs wherever Flutter runs (I think).
- **Flutter's layout, on nodes.** `RowNode`, `ColumnNode`, and `BoxNode` behave like the widgets you already know.
- **Asset preloading.** `Preload` concurrently loads assets with `Loader`s for images, data, or custom resource types.
- **Live assets.** When developing on the host machine, `LocalAssetBundle` instantly reloads assets into the global cache.
- **Live nodes.** Any node can opt into rebuilding itself on save, so your edits land in the running game.

## Start Here

- [Motivation](/motivation) - why this exists when Flame already does.
- [Your first scene](/start) - a running game, and an edit you make while it runs.
- [Building](/concepts/building) - the one rule the rest of the engine is shaped around.

## Attribution

Every sprite the demos on this site draw - the slime, the bonfire, the explosion - is by [Infected Tribe](https://infectedtribe.itch.io/). The mark in the header is a painting by [Mewyn](https://mewyn.itch.io/).
