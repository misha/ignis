---
title: Live Reload
description: What a save does to a running game, and how to ask for more.
lane: usage
category: system
status: stub
---

<!-- Scope: the payoff of the whole refactor. reassemble as opt-in, implementing it with rebuild, the two triggers (SceneWidget reassembling, Ignis.cache changing), LocalAssetBundle. -->
<!-- Source: lib/src/node.dart:77-89 and :661-691, lib/src/flutter/scene_widget.dart:40,61, lib/src/assets/local_bundle_io.dart, README.md:775-859. Note: SpriteNode is currently the only node in the engine that overrides reassemble. -->

<Demo name="live-reload"/>

In the course of game development, you will soon find yourself needing to iterate on code in a certain game state. The typical loop is to make a change, compile the code, and restart the game. In short, dreadfully slow.

Game engines that can live reload drastically accelerate this loop. Every running game is already an iterative environment!

Ignis commits to giving you the tools to create the perfect, live-reloading game. It grants the programmer the ability to *rebuild* objects while maintaining their state, as well as explicit control over the scope and severity of the reload sequence itself.

This capability is made possible by leveraging Dart's incredible ability to dynamically update method bodies in running applications. This is particularly insane given Dart is a statically-typed, compiled language!

## The Rule

## Opting In

A save leaves a running game exactly as it was unless a node answers for itself. The default answer is nothing.

## Reloading Assets
