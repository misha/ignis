---
title: Nodes
description: The tree, where code goes, and what a rebuild keeps.
lane: usage
category: concept
status: stub
---

<!-- Scope: Node as the primitive. add/remove/detach, priority, enabled, children and query<T>, ancestors and descendants. Source: lib/src/node.dart:15-89, README.md:96-125. Ceiling: no catalog of node types - that is /systems/nodes. -->
<!-- The keystone. Ignis' Rules of Hooks: the rules you follow. -->
<!-- Source: lib/src/node.dart:199-260 (build, rebuild), :283-343 (tick, draw, trash), README.md:126-252. The derived/preserved/imperative table at README.md:222-251 is the centerpiece and must become a demo with a rebuild button. -->

<Demo name="node-tree"/>

## The Rule

## Declare in `build`

<Demo name="rebuild-boundary"/>

## Priority Decides Order

## Enabling and Disabling

## What a Rebuild Destroys

## Rebuild Boundaries

## What `trash` Owns

<Warning>

  State that must survive a rebuild belongs on the node or on a preserved child, never on a derived one.

</Warning>
