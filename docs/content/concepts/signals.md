---
title: Signals
description: Who owns a subscription, and why it matters.
lane: usage
category: concept
status: stub
---

<!-- Scope: Signal0..3, the on- prefix convention, and the ownership split - subscribing inside build hands the Cleanup to the node, everywhere else the caller owns it. Source: lib/src/signal.dart:1-30, lib/src/node.dart:41-49, README.md:287-321. Ceiling: the sealed Signal base and the reentrancy tombstoning are internals. -->

<Demo name="signal-ownership"/>

## The rule

## Naming a signal

## Who owns the `Cleanup`

## Getting it wrong

## What this doesn't do
