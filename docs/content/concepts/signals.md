---
title: Signals
description: Who owns a subscription, and why it matters.
lane: usage
category: concept
status: complete
---

Nodes communicate time-sensitive events through `Signal`, a lightweight message emitter.

By convention, signals are prefixed with `on` so subscriptions read naturally in a node's [`build()`](/concepts/nodes).

```dart
// Declare a signal with 1 parameter. There are Signal0, Signal1, ...
final onCollisionStart = Signal1<ColliderNode>();

// Call a signal with a function argument to watch it.
final cleanup = onCollisionStart((other) => print('Hit $other!'));

// Emit sends a type-safe message to all watchers.
onCollisionStart.emit(someCollider);

// Stop watching the signal.
cleanup();
```

`Signal0` through `Signal3` carry zero to three arguments, each typed.

<Lineage from="Godot">

  The name *signal* is taken from the parallel concept in Godot.

</Lineage>

## Ownership

Watching a signal returns a `Cleanup`, and somebody has to own it. Inside a node's `build()`, that somebody is the node: the subscription is automatically torn down on the next rebuild or unmount:

```dart
@override
void build() {
  super.build();
  // No need to assign `cleanup` here!
  // The node magically knows about this subscription.
  onCollisionStart(/* some behavior */);
}
```

Watching signals in `build()` needs no bookkeeping at all, but everywhere else, it does. Hold on to the `Cleanup` and call it, or the signal keeps a reference to your watcher indefinitely.

## Outside a Node

Although nodes are driven by signals, `Signal` is a standalone utility class and may be used anywhere. Notably, signals can easily be used to implement communication between your Flutter app and your Ignis game. Here's an example integration using [`flutter_hooks`](https://pub.dev/packages/flutter_hooks).

```dart
/// Calls [handle] whenever [signal] is emitted.
void useSignal0(Signal0 signal, void Function() handle) {
  useEffect(() => signal(handle), [signal, handle]);
}
```

## Why Not `ChangeNotifier`

`ChangeNotifier` is similar to `Signal`, but it was made for *widgets*, not nodes. `ChangeNotifier` has limited performance, lack of N-argument typing, and an obligation to call `dispose`. Signals are fast, support specific argument counts, and do not require disposal.
