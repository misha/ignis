---
title: Live Reload
description: Implementing live nodes.
lane: usage
category: system
status: partial
reference: [Node, Live]
related: [/concepts/nodes, /concepts/signals]
---
<!-- SPDX-AI-Disclosure: none -->

When developing a game, you will inevitably find yourself making minor adjustments to your code: tweak a size, adjust a color, bump a velocity. It can take quite a few adjustments to get something looking and feeling just right!

In order to accelerate this common development loop, Ignis offers a special tool, the `Live` mixin, that allows the programmer to instrument any `Node` with implementation-specific live reload behavior. Using `Live`, you can granularly specify which parts of a node are reset or kept when your code changes.

## The `Live` Mixin

By default, nodes are not instrumented for live reload. When your Dart code reassembles, no additional code is run. Sometimes, code *happens* to be in a raw method body, causing it to reload without intervention.

But *nodes* are defined primarily through closures: `tick` and `draw` are not raw method bodies, but rather lists of stored closures. As a result, for the most part, changing your code will have minimal impact on a live Ignis scene.

This changes with the `Live` mixin. When `Live` is applied to a node, **every reassembly will `build()` the node again**. To illustrate, consider the rotating squares below.

```dart
const SPEED = pi / 4;

class MySquare extends ShapeNode {
  MySquare() : super(shape: .square(10));

  @override
  void build() {
    super.build();
    tick((dt) => angle += SPEED * dt);
  }
}

class MyLiveSquare extends ShapeNode with Live {
  MyLiveSquare() : super(shape: .square(10));

  @override
  void build() {
    super.build();
    tick((dt) => angle += SPEED * dt);
  }
}
```

If you modify `SPEED` and save your code, `Live` will tear down *everything* produced in the original `build()` call, including nodes added, signals subscribed, and `tick` and `draw` callbacks installed. Then, `Live` will call `build()` again from the top.

In this new build pass, `SPEED` holds the updated value, so **`MyLiveSquare` will rotate at the new speed**. Meanwhile, `MySquare` will continue rotating at the old speed, because its `tick` closure still references the old value.

## Keeping What's Important

By default, `Live` is an indiscriminate sledgehammer: it simply reboots the entire node without nuance. Consider the following scenario:

```dart
class PaddedGameNode extends Node with Live {
  @override
  void build() {
    super.build();

    add(
      BoxNode(
        padding: .all(10),
        children: [
          GameNode(),
        ],
      ),
    );
  }
}
```

Perhaps you wanted to play with the `padding`, so you opted into `Live`. But as an unfortunate side effect, `GameNode()` is completely recreated with every reassemble! It's quite literally a brand new game with each code change.

To address this scenario, the `Live` mixin offers a single public method: `keep`. Given a symbolic name and a closure, `keep` will maintain instances across reloads. Applying it to the example above, you could allow `padding` to live reload while keeping the same `GameNode` instance alive as follows:

```dart
class PaddedGameNode extends Node with Live {
  @override
  void build() {
    super.build();

    add(
      BoxNode(
        padding: .all(10),
        children: [
          // As long as the symbol matches, the same `GameNode` persists.
          keep(#game, () => GameNode()),
        ],
      ),
    );
  }
}
```

<Info>

  Experiencing déjà vu? If you've used `flutter_hooks` and know `useMemoized`, the mechanism Ignis uses to maintain instances across rebuilds is remarkably similar. However, instead of relying on declaration order as an implicit name, `keep` requires an explicit, symbolic name. In exchange for this verbosity, the "laws of hooks" do not apply: you can move `keep(#game, ...)` virtually anywhere inside the body of `build` and it will happily retain its live instance.

</Info>

## Future Documentation

Note that this page is incomplete, and doesn't quite cover the semantics of `keep` or its usage with collections. The documentation will be written later. Check out the `dart doc` on `Live` for details on the current API.
