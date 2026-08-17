---
title: Sprites
description: Cutting a sheet into frames, and playing them.
lane: usage
category: system
status: stub
---

<!-- Catalog: Spritesheet, Spritesheet.asset, SpriteNode, SpriteNode.split, play({sheet, row, column}), fps, loop, cleanup, and the onFrame/onLoop/onFinish signals. README.md:523-528 omits play's column parameter. -->
<!-- SpriteNode is the one node in the engine that overrides reassemble - it re-resolves its sheets against the cache rather than rebuilding. Worth showing, and it links to /concepts/live-reload. Source: lib/src/nodes/sprite_node.dart, lib/src/spritesheet.dart, README.md:509-547. -->

<Demo name="sprite-animation"/>

## The catalog

## Cutting a sheet

## Playing frames

## Surviving a reload

## What this doesn't do
