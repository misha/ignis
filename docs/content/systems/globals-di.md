---
title: Globals and DI
description: Two injection stories, and when each applies.
lane: usage
category: system
status: stub
---

<!-- Catalog: Ignis.bundle, Ignis.cache, Ignis.preload; and Node.provide<T>, read<T>, readOrNull<T>. -->
<!-- The one non-obvious rule: read is not reactive. It caches until unmount, so a later provide for the same type is not picked up. Source: lib/src/node.dart:734-784, lib/src/globals.dart, README.md:860-902. -->
<!-- Worth saying plainly that a game may skip Ignis' DI entirely and pass a riverpod container down instead, as voltaire does. -->

<Demo name="provide-read"/>

## The catalog

## Globals

## Providing down a subtree

`read` is not reactive. The result is cached until the node unmounts, so a later `provide` for the same type will not be picked up.
