---
title: Live Reload
description: What a save does to a running game, and how to ask for more.
lane: usage
category: system
status: partial
---

In the course of game development, you will soon find yourself needing to iterate on code in a certain game state. The typical loop is to make a change, compile the code, and restart the game. In short, dreadfully slow.

Game engines that can live reload drastically accelerate this loop. Every running game is already an iterative environment!

Ignis commits to giving you the tools to create the perfect, live-reloading game. It grants the programmer the ability to *rebuild* objects while maintaining their state, as well as explicit control over the scope and severity of the reload sequence itself.

This capability is made possible by leveraging Dart's incredible ability to dynamically update method bodies in running applications. This is particularly insane given Dart is a statically-typed, compiled language!

## The Rule

## Opting In

A save leaves a running game exactly as it was unless a node answers for itself. The default answer is nothing.

A node capable of completely reconstructing itself from its own `build()` can answer with `rebuild()`:

```dart
@override
void reassemble() => rebuild();
```

This enables the highest form of live reload: *everything* the node does will update as you write code.

The rest of this page applies to a node that answers this way. One that answers with something else, or with nothing, never rebuilds, and never has a rebuild boundary to think about.

## Rebuilding

`rebuild()` re-derives a node by running `build()` again over the wreckage of the last one. Everything the previous build made is thrown away:

- The children it created.
- The `tick`, `draw`, and `debugDraw` callbacks it registered.
- The signals it subscribed to.
- Everything in its `trash`.

What survives is the node itself: its members, its transform, and anything added to it imperatively.

Because the body runs again from the top, the constructor arguments *inside* it are re-evaluated, exactly like a statement is. That is what lets an edited `build()` show up in a running game.

## Declared and Imperative

A child added inside `build()` is *declared*: the body decides again on every rebuild whether it is still there. A child added anywhere else - a constructor, a signal handler, the middle of gameplay - is *imperative*, and a rebuild leaves it alone entirely.

```dart
@override
void build() {
  super.build();

  // Declared, so it is replaced on every rebuild.
  final spawner = add(TimerNode(interval: 1, repeat: true));

  spawner.onTrigger(() {
    // Imperative. Nothing rebuilds these.
    add(EnemyNode());
  });
}
```

## Rebuild Boundaries

Declaring a child decides whether it belongs in the tree. Where you *construct* it decides whether it is rebuilt along with its parent. The two are independent, and that is the whole knob.

| Child      | Constructed      | Added             | On a rebuild                   |
|------------|------------------|-------------------|--------------------------------|
| Derived    | inside `build()` | inside `build()`  | Destroyed, then built fresh    |
| Preserved  | on the instance  | inside `build()`  | Kept; the rebuild passes it by |
| Imperative | anywhere         | outside `build()` | Untouched                      |

A preserved child is a **rebuild boundary**. It never leaves the tree, so the rebuild above it does not re-run its `build()` or disturb anything beneath it. Reach for one when a subtree owns state you cannot recreate.

```dart
class GameNode extends Node {
  // Preserved. The simulation survives however often this node rebuilds.
  final world = WorldNode();

  @override
  void build() {
    super.build();

    add(world);

    // Derived. Rebuilt from scratch on every save.
    add(HudNode(world: world));
  }
}
```

The boundary stops the rebuild, not the reload: the reassembly walk still reaches a preserved child, so it remains free to answer for itself. And a body that stops declaring one drops it like any other declaration, so `build()` stays the single source of truth about who is in the tree.

<Warning>

  State that must survive a rebuild belongs on the node or on a preserved child, never on a derived one.

</Warning>

## Reloading Assets

```
// TODO
```
