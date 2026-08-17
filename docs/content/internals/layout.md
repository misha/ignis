---
title: The layout engine
description: Constraints down, sizes up, once per tick.
lane: internals
category: internal
status: stub
---

<!-- Walk lib/src/layout/layout_engine.dart, layout_constraints.dart, layout_flex.dart, and lib/src/nodes/layout_node.dart. -->

<!-- Diagram: LayoutEngine already carries ASCII worked examples at lib/src/layout/layout_engine.dart:16-60 and :150-165. Lift them onto the page rather than writing new ones or restating them in prose. -->

## The invariant

<!-- Constraints travel down, sizes travel back up, and a node never sizes itself from its own children before its parent has told it what it may be. Same contract as Flutter's, which is the point - a reader who knows RenderBox already knows this. -->

## Constraints down

<!-- lib/src/layout/layout_constraints.dart. Tight, loose and unbounded, and the constrain/enforce/loosen/deflate/descale operations. -->

## Sizes up

<!-- lib/src/layout/layout_engine.dart:62, LayoutEngine.box. The single-child case first, because it is the one the reader can hold in their head. -->

## Distributing flex

<!-- lib/src/layout/layout_engine.dart:166 and :314, LayoutEngine.flex and distributeSpace. LayoutFlex.none, .expanded() and .flexible(), and the two passes: inflexible children first, then the remainder split by flex factor. -->

## Placement

<!-- lib/src/layout/layout_engine.dart:295 and :339, place and crossAxisOffset. How MainAxisAlignment and CrossAxisAlignment resolve to offsets. -->

## Re-laying every tick

<!-- lib/src/nodes/layout_node.dart. A layout root re-lays itself every frame rather than tracking invalidation. Say what that costs and why it was chosen - there is a benchmark number for it. -->

## What this doesn't do
