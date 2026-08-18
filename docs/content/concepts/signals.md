---
title: Signals
description: Who owns a subscription, and why it matters.
lane: usage
category: concept
status: stub
---

<!-- Scope: Signal0..3, the on- prefix convention, and the ownership split - subscribing inside build hands the Cleanup to the node, everywhere else the caller owns it. Source: lib/src/signal.dart:1-30, lib/src/node.dart:41-49, README.md:287-321. Ceiling: the sealed Signal base and the reentrancy tombstoning are internals. -->

<Demo name="signal-ownership"/>


<!-- Saved content from the original README: -->

<Why>

  **Why not `ChangeNotifier`?** `ChangeNotifier` is similar to `Signal`, but it was made for widgets, not nodes. `ChangeNotifier` comes with three drawbacks: poor performance, lack of N-argument typing, and a requirement to call `dispose`. Signals are fast, support specific argument counts, and do not require disposal.

</Why>

## The Rule

## Naming a Signal

## Who Owns the `Cleanup`
