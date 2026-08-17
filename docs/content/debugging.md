---
title: Debugging
description: Seeing what the engine is actually doing.
lane: usage
category: system
status: stub
---

<!-- Expected to grow into its own group. Today the engine offers: SceneWidget's debug flag, Node.debugDraw, scene.render(canvas, debug: true), and FpsNode. Source: lib/src/node.dart:158-180 and :316-320, lib/src/scene.dart:50-57, lib/src/nodes/fps_node.dart. The README has no debugging section at all. -->
<!-- Known gap to state rather than paper over: DEBUG_TRANSFORM_PAINT is @internal and unexported, so README.md:180's debugDraw sample cannot compile for a reader. Either the constant gets exported or the sample changes; decide before this page ships. -->

<Demo name="debug-overlay"/>

## The debug overlay

## Drawing your own

## Reading a stuck frame

## What this doesn't do
