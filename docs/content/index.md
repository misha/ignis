---
title: Ignis
description: A 2D Flutter game engine built on nodes and signals.
image: /images/ignis.webp
imageAlt: The Ignis mark, a painting of a flame.
lane: usage
category: essay
status: complete
---
<!-- SPDX-AI-Disclosure: none -->

- **Embrace composition.** *Everything* is a `Node`. Compose behavior and graphics with trees.
- **Completely synchronous.** Nodes are built and rendered in a synchronous loop. Errors are reported at the source.
- **Signals over callbacks.** The `Signal`, a lightweight event emitter, powers everything from animations to collisions.
- **Embedded in Flutter.** Any node can be rendered in the widget tree via `SceneWidget`. Ignis runs wherever Flutter runs.
- **Live nodes.** Any node can opt into rebuilding itself on save, so your edits land in the running game.
- **Live assets.** When developing on the host machine, `LocalAssetBundle` instantly reloads assets into the global cache.

<Demo name="spinner"/>

<Info>

  Every demo on this site is a real Ignis scene compiled into the page, not a recording or a code sample.

</Info>

## Start Here

- [Motivation](/motivation) - why this engine exists.
- [Nodes](/concepts/nodes) - how to use a `Node`.

## Attribution

The mark in the header is a beautiful painting by [Mewyn](https://mewyn.itch.io/).

The example assets in the demos are provided by [Infected Tribe](https://infectedtribe.itch.io/).
