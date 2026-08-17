---
title: The tree
description: Why a mounted tree defers its own edits.
lane: internals
category: internal
status: stub
---

<!-- Walk lib/src/tree.dart and lib/src/egg.dart. Both are already well commented, so this page can reach partial quickly. -->

<!-- Diagram: one frame, as a plain fence.
     flush queued ops -> tick -> render
     and where an add() called from inside a tick actually lands. -->

## The invariant

<!-- The tree is never mutated while it is being walked. Before mount, add/remove/priority apply immediately, because nothing is iterating. After mount they are enqueued and applied at one known point in the frame. -->

## The operation queue

<!-- lib/src/tree.dart. The pooled Queue<_Operation> of add, remove and reposition, and why operations are pooled rather than allocated. An add and a remove queued in the same frame settle to nothing - lib/src/node.dart:623-631. -->

## Flushing before the tick

<!-- lib/src/scene.dart:29-34. The single point where the queue drains, and why it is before update rather than after render. -->

## Egg and the type index

<!-- lib/src/egg.dart. The priority-sorted child list, and the per-type _Index that backs query<T>(). Maintained incrementally as children come and go rather than invalidated, which is why repeated query<T>() calls allocate nothing - lib/src/node.dart:450-458. -->

## What this doesn't do
