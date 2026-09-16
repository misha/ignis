---
title: Signals
description: Who owns a subscription, and why it matters.
lane: usage
category: concept
status: complete
related: [/concepts/nodes, /systems/nodes]
---
<!-- SPDX-AI-Disclosure: none -->

Nodes communicate time-sensitive events through `Signal`, a lightweight message emitter.

By convention, signals are prefixed with `on` so subscriptions read naturally in a node's `build` method.

Subscribing to a signal returns a `Cleanup` callback. It must be called to avoid leaking the subscription.

```dart
// Declare a signal with 1 parameter. There are Signal0, Signal1, ...
final onCollisionStart = Signal1<ColliderNode>();

// Call a signal with a callback argument to subscribe to it.
final Cleanup cleanup = onCollisionStart((ColliderNode other) => print('Hit!'));

// Emit sends a type-safe message to all subscribers.
onCollisionStart.emit(someCollider);

// Unsubscribe from the signal.
cleanup();
```

Signals are implemented from `Signal0` up to `Signal3`. The number at the end indicates the number of arguments and type parameters, letting each signal retain type safety.

<Lineage from="Godot">

  The name *signal* is taken from the parallel concept in Godot.

</Lineage>

## Inside `build`

Remembering to unsubscribe is annoying and bug-prone. To help with this, when you subscribe to a signal inside a node's `build` method, **Ignis will automatically unsubscribe for you on unmount or rebuild**.

```dart
@override
void build() {
  super.build();
  // The node knows about this subscription and will automatically clean it up:
  onCollisionStart(/* some behavior */);
  // It's almost as if `trash(cleanup)` is magically executed for you.
}
```

In practice, the *vast* majority of subscriptions occur inside `build`, resulting in minimal bookkeeping. Everywhere else: hold on to the `Cleanup` and call it, or the signal keeps a reference to your callback indefinitely.

## Outside `build`

Although nodes use signals, `Signal` itself is a standalone utility class and may be used anywhere.

Notably, signals can easily be used to implement communication between your Flutter app and your Ignis game. Here's an example integration using [`flutter_hooks`](https://pub.dev/packages/flutter_hooks).

```dart
/// Calls [handle] whenever [signal] is emitted.
void useSignal0(Signal0 signal, void Function() handle) {
  useEffect(() => signal(handle), [signal, handle]);
}
```

## Why Not `ChangeNotifier`

`ChangeNotifier` is similar to `Signal`, but it was made for *widgets*, not nodes. `ChangeNotifier` has limited performance, lack of N-argument typing, and an obligation to call `dispose`. Signals are fast, support specific argument counts, and do not require disposal.
