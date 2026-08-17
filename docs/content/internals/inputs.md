---
title: Input Routing
description: How a pointer finds a node.
lane: internals
category: internal
status: stub
---

<!-- Walk lib/src/node.dart:695-731, lib/src/flutter/input_router.dart, and lib/src/nodes/input_node.dart, following one pointer event from the widget to a handler. -->

<!-- Diagram: the walk as a plain fence. A small tree with priorities, the order hitTest visits it in, and where the search stops for opaque against translucent. -->

## The invariant

<!-- The first thing tried is the topmost thing you can see. Hit testing walks children in reverse priority order before the node's own hit area, which is exactly reverse paint order - so the picture on screen is the specification for the walk. -->

## The walk

<!-- lib/src/node.dart:707-718. Children reversed, then self, yielded lazily as an Iterable. Note the documented oddity: enabled takes effect immediately mid-walk, unlike every other tree operation, so a handler that disables an unvisited node affects the same walk. lib/src/node.dart:701-705 carries an open TODO asking whether that is right - state it as an open question rather than a design. -->

## Opting into being hit

<!-- lib/src/node.dart:720-731. containsPoint defaults to false, so a plain node is invisible to the walk and only a node that overrides it participates. lib/src/nodes/input_node.dart implements the circle and rectangle cases. -->

## Handing off to Flutter

<!-- lib/src/flutter/input_router.dart. Ignis finds the node; Flutter's own MultiTapGestureRecognizer and ImmediateMultiDragGestureRecognizer decide what the gesture was. Say why reimplementing recognizers was never on the table. -->

## Claiming and falling through

<!-- HitBehavior.opaque against .translucent, and what InputResult.handled does to the search. An event a node does not apply to falls through; an event it claims stops the search unless it is translucent. -->
