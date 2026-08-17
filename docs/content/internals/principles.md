---
title: Principles
description: The three commitments every other decision in the engine answers to.
lane: internals
category: internal
status: stub
---

<!-- The root of the Internals lane. Every other page here should be traceable back to one of these three and should link up to it. This is the one internals page that argues rather than walks code, because the commitments are prior to the code. -->

<!-- Diagram: one frame as a plain fence - flush, tick, render - since the other pages all locate themselves against it. -->

## Synchronousness

<!-- Nodes are constructed, updated and rendered in one synchronous loop, and errors surface at the source. What it buys: no partially-initialized nodes, no awaiting mid-frame, no question of what to render while something loads. What it costs: preloading is mandatory, and build must never be async - lib/src/node.dart:38-39 calls an async build devastating and should say here exactly which invariants it breaks. -->

## Code Locality

<!-- A node's children, its signal wiring and its per-frame behavior are declared in one method. The bags exist so behavior has a location that can be discarded and re-derived, rather than being spread across virtual method overrides that cannot. -->

## Reloadability

<!-- The one that pays for the other two. Because a build is a single re-runnable declaration over an instance that survives it, the engine can throw away everything a build made and run it again over the wreckage. That is what makes node-level live reload achievable rather than approximated. What it demands of everything else: no constructor-time side effects, no state on derived children, every subscription owned by a build, every resource in the trash. -->
