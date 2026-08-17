---
title: Effects
description: Nodes that finish, and what each one animates.
lane: usage
category: system
status: stub
---

<!-- Catalog, 13 rows: MoveEffect, RotateEffect, ScaleEffect, AnchorEffect, ColorOpacityEffect, ColorFilterOpacityEffect, CombinedEffect, SequentialEffect, FollowEffect, SpinEffect, VelocityEffect, plus the EffectNode base and cleanup. Per row: what it animates, its factories, and whether .speed() applies. -->
<!-- Note README.md:449-472 omits FollowEffect, SpinEffect and VelocityEffect. Asymmetries a reader will hit: SpinEffect and VelocityEffect take no cleanup because they never finish; AnchorEffect is the one .by/.to effect .speed() does not work with. -->
<!-- Ceiling: EffectTarget, ControlledEffect and MeasurableEffect are internals. Say "animates the nearest ancestor that has a position", not the class that resolves it. -->

<Demo name="effect-gallery"/>

## The catalog

## An effect animates what is above it

## Finishing and cleanup
