---
title: Live Reload
description: What a save does to a running game, and how to ask for more.
lane: usage
category: concept
status: stub
---

<!-- Scope: the payoff of the whole refactor. reassemble as opt-in, implementing it with rebuild, the two triggers (SceneWidget reassembling, Ignis.cache changing), LocalAssetBundle. -->
<!-- Source: lib/src/node.dart:77-89 and :661-691, lib/src/flutter/scene_widget.dart:40,61, lib/src/assets/local_bundle_io.dart, README.md:775-859. Note: SpriteNode is currently the only node in the engine that overrides reassemble. -->

<Demo name="live-reload"/>

## The Rule

## Opting In

A save leaves a running game exactly as it was unless a node answers for itself. The default answer is nothing.

## Reloading Assets

## Getting It Wrong
