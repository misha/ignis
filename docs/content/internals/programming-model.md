---
title: The programming model
description: How a build is recorded, discarded, and run again.
lane: internals
category: internal
status: stub
---

<!-- The pair to /concepts/building: that page is the rules you follow, this one is the code that enforces them. Walk lib/src/node.dart in the order the machine runs it. -->

## The invariant

<!-- A build is a single re-runnable declaration over an instance that outlives it. Everything a build made can be identified and thrown away; everything on the instance survives. Without that, rebuild cannot be safe, and node-level live reload is approximation rather than fact. -->

## The four bags

<!-- lib/src/node.dart:283-345. _ticks, _draws, _debugDraws, _cleanups, each null until first use, each appended by a same-named verb method. Show why null-until-used matters for a tree of thousands of nodes that mostly do one thing each. -->

## The builder static

<!-- lib/src/node.dart:194-197 and lib/src/signal.dart:20-30. _builder is how a Signal subscribed anywhere inside build() finds the node that owns it, without the caller passing anything. This is the whole ownership story in nine lines. -->

## Declared children

<!-- lib/src/node.dart:262-276 and :574-604. _declared records what this build added, so the next rebuild knows what to discard. A child re-added by the new body has its pending removal cancelled rather than being replaced, which is what makes a child held on the instance a boundary. -->

## Rebuild, in order

<!-- lib/src/node.dart:209-260. Discard declared, drop the bags, empty the trash, run build again, re-emit onSceneResize. Two details worth their own paragraph: the bags are dropped rather than cleared so a rebuild triggered from inside a tick does not corrupt the list being iterated; and the trash empties most-recent-first so a teardown that emits runs before the handlers it notifies are gone. -->
