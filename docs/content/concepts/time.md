---
title: Time
description: There is no clock. There is only `dt`.
lane: usage
category: concept
status: complete
---
<!-- SPDX-AI-Disclosure: none -->

## Unit

In Ignis, the unit of time and duration is **seconds**, always expressed as a `double`.

## Ticks

Nodes can hook into the game loop with `tick`:

```dart
// Do something every frame...
tick((double dt) {
  // `dt` seconds elapsed this frame.
  // This is usually quite small, e.g. 0.01666 at 60 FPS.
});
```

Anything that happens at a rate should be scaled on the way in. For example, a velocity in units per second becomes a distance when scaled by `dt`:

```dart
tick((double dt) {
  position.addScaled(velocity, dt);
});
```

Additionally, all Ignis objects that accept an interval or duration are expressed in seconds.

```dart
// Triggers after 200 milliseconds.
final timer = TimerNode(interval: 0.2);

// Progresses an effect over the course of 1.5 seconds.
final timeline = Timeline.duration(1.5);
```
