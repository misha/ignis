---
title: Effect controllers
description: What drives an effect's timing, and how controllers nest.
lane: usage
category: system
status: stub
---

<!-- Catalog, 9 rows: duration, speed, wait, terminal, once, repeat, infinite, roundtrip, sequence. Note README.md:490-498 omits speed and terminal. -->
<!-- Reach them through the shorthand factories (lib/src/effects/effect_controller.dart:61-69), not the class names - that is what a reader types: controller: .infinite(.roundtrip(.duration(0.4))). -->
<!-- Also here: SineCurve and ZigzagCurve, which range -1 to 1 rather than Flutter's 0 to 1. Source: lib/src/effects/controllers/, lib/src/curves/, README.md:473-508. -->

<Demo name="controller-comparison"/>

## The catalog

## Nesting controllers

## Curves

## What this doesn't do
