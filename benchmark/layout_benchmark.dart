// ignore_for_file: invalid_use_of_internal_member

import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flutter/rendering.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// Randomly generated layout trees, re-laid out from scratch on every tick.
class LayoutBenchmark extends AsyncBenchmarkBase {
  final int seed;
  final int trees;
  final int depth;
  final int breadth;
  final int ticks;
  final Random random;

  late Scene<Node> scene;

  LayoutBenchmark({
    this.seed = 12345,
    this.trees = 50,
    this.depth = 5,
    this.breadth = 3,
    this.ticks = 100,
  }) : random = Random(seed),
       super('Layout');

  @override
  Future<void> setup() async {
    final root = Node();

    for (var i = 0; i < trees; i += 1) {
      root.add(generate(depth, boundedX: true, boundedY: true));
    }

    scene = root.mount();
    scene.resize(800, 600);
  }

  @override
  Future<void> run() async {
    for (var t = 0; t < ticks; t += 1) {
      scene.update(1 / 60);
    }
  }

  @override
  Future<void> teardown() async => scene.destroy();

  /// A random subtree [depth] levels deep, to be laid out under constraints
  /// whose axes are bounded per [boundedX] and [boundedY].
  ///
  /// Boundedness is threaded through generation because two choices are only
  /// legal on a bounded axis, and picking them blindly would generate trees
  /// the engine rejects rather than trees it lays out:
  ///
  /// - A flex child, which `LayoutEngine.flex` asserts against when the main
  ///   axis is unbounded (there is no leftover space to divide).
  /// - `CrossAxisAlignment.stretch`, which pins each child's cross-axis
  ///   minimum to the incoming maximum, and so would force an infinite
  ///   minimum on an unbounded axis.
  ///
  /// A `FlexNode` measures its non-flex children with an unbounded main
  /// axis, so nesting alone is enough to reach both cases.
  SizedNode generate(
    int depth, {
    required bool boundedX,
    required bool boundedY,
  }) {
    if (depth == 0) return ShapeNode(shape: .square(extent(4, 24)));

    return switch (random.nextInt(5)) {
      0 => box(depth, boundedX: boundedX, boundedY: boundedY),
      1 => padding(depth, boundedX: boundedX, boundedY: boundedY),
      2 => align(depth, boundedX: boundedX, boundedY: boundedY),
      3 => flex(depth, .horizontal, boundedX: boundedX, boundedY: boundedY),
      _ => flex(depth, .vertical, boundedX: boundedX, boundedY: boundedY),
    };
  }

  /// A [BoxNode] with each axis independently fixed or left to its children.
  /// A fixed axis bounds that axis for everything underneath.
  BoxNode box(
    int depth, {
    required bool boundedX,
    required bool boundedY,
  }) {
    final width = random.nextBool() ? extent(32, 256) : null;
    final height = random.nextBool() ? extent(32, 256) : null;

    return BoxNode(
      width: width,
      height: height,
      padding: insets(),
      children: descend(
        depth,
        boundedX: boundedX || width != null,
        boundedY: boundedY || height != null,
      ),
    );
  }

  /// A [PaddingNode], which deflates its constraints without changing which
  /// axes are bounded.
  PaddingNode padding(
    int depth, {
    required bool boundedX,
    required bool boundedY,
  }) {
    return PaddingNode(
      padding: insets(),
      children: descend(
        depth,
        boundedX: boundedX,
        boundedY: boundedY,
      ),
    );
  }

  /// An [AlignNode], which loosens its constraints without changing which
  /// axes are bounded.
  AlignNode align(
    int depth, {
    required bool boundedX,
    required bool boundedY,
  }) {
    return AlignNode(
      alignment: .new(random.nextDouble(), random.nextDouble()),
      children: descend(
        depth,
        boundedX: boundedX,
        boundedY: boundedY,
      ),
    );
  }

  /// A [RowNode] or [ColumnNode] along [direction], with a random share of
  /// its children wrapped in flex nodes.
  ///
  /// Non-flex children are measured with an unbounded main axis; flex
  /// children get a finite slice of the leftover space instead. The cross
  /// axis passes through untouched.
  FlexNode flex(
    int depth,
    Axis direction, {
    required bool boundedX,
    required bool boundedY,
  }) {
    final horizontal = direction == Axis.horizontal;
    final boundedMain = horizontal ? boundedX : boundedY;
    final boundedCross = horizontal ? boundedY : boundedX;
    final children = <Node>[];
    final count = 1 + random.nextInt(breadth);

    for (var i = 0; i < count; i += 1) {
      final flexible = boundedMain && random.nextInt(3) == 0;
      final child = generate(
        depth - 1,
        boundedX: horizontal ? flexible : boundedX,
        boundedY: horizontal ? boundedY : flexible,
      );

      children.add(flexible ? wrap(child) : child);
    }

    final mainAxisAlignment =
        MainAxisAlignment.values[random.nextInt(MainAxisAlignment.values.length)];
    final crossAxisAlignment = crossAlignment(boundedCross);
    final mainAxisSize = random.nextBool() ? MainAxisSize.max : MainAxisSize.min;
    final reverse = random.nextBool();
    final spacing = extent(0, 8);

    return switch (direction) {
      .horizontal => RowNode(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        reverse: reverse,
        spacing: spacing,
        children: children,
      ),
      .vertical => ColumnNode(
        mainAxisAlignment: mainAxisAlignment,
        crossAxisAlignment: crossAxisAlignment,
        mainAxisSize: mainAxisSize,
        reverse: reverse,
        spacing: spacing,
        children: children,
      ),
    };
  }

  /// Wraps [child] so an ancestor [FlexNode] gives it a share of the
  /// leftover main-axis space. Both wrappers hold a single child, which is
  /// all [FlexibleNode] supports.
  FlexibleNode wrap(SizedNode child) {
    final factor = 1 + random.nextInt(3);

    return random.nextBool()
        ? ExpandedNode(flex: factor, children: [child])
        : FlexibleNode(flex: factor, children: [child]);
  }

  /// Between one and [breadth] subtrees, one level shallower.
  List<Node> descend(
    int depth, {
    required bool boundedX,
    required bool boundedY,
  }) {
    return List.generate(
      1 + random.nextInt(breadth),
      (_) => generate(depth - 1, boundedX: boundedX, boundedY: boundedY),
    );
  }

  /// A random [CrossAxisAlignment], falling back to `center` when `stretch`
  /// comes up on an unbounded cross axis.
  CrossAxisAlignment crossAlignment(bool boundedCross) {
    final alignment = CrossAxisAlignment.values[random.nextInt(CrossAxisAlignment.values.length)];
    if (alignment == .stretch && !boundedCross) return .center;
    return alignment;
  }

  /// A random extent in `[min, max)`.
  double extent(double min, double max) => min + random.nextDouble() * (max - min);

  /// Random padding, small enough to leave room for content.
  EdgeInsets insets() => .all(random.nextDouble() * 8);
}

Future<void> main() async {
  await runBenchmark(LayoutBenchmark());
}
