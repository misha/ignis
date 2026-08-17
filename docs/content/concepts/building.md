---
title: Building
description: Where code goes, and what a rebuild keeps.
lane: usage
category: concept
status: stub
---

<!-- The keystone. Ignis' Rules of Hooks: the rules you follow, not the machine that enforces them - that is /internals/programming-model. -->
<!-- Source: lib/src/node.dart:199-260 (build, rebuild), :283-343 (tick, draw, trash), README.md:126-252. The derived/preserved/imperative table at README.md:222-251 is the centrepiece and must become a demo with a rebuild button. -->

<Demo name="rebuild-boundary"/>

## Declare in `build`

## What a rebuild destroys

## Rebuild boundaries

## What `trash` owns

## Getting it wrong

<Rule>
  State that must survive a rebuild belongs on the node or on a preserved child, never on a derived one.
</Rule>
