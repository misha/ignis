// ignore_for_file: invalid_use_of_internal_member

import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flutter/rendering.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// Randomly generated layout trees, re-laid out from scratch on every tick.
///
/// Every tree is its own layout root, so a single `scene.update` drives a
/// full constraint-propagation pass over all of them: measure, distribute,
/// place, top to bottom. Nothing else runs, so the tick cost is the layout
/// cost.
///
/// Trees mix every layout node the engine ships, which keeps the measurement
/// honest about the mix a real UI hits rather than one node type in a loop.
/// Generation is deterministic for a given [seed].
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
      root.add(generate(depth));
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

  /// A random subtree [depth] levels deep, bottoming out in fixed-size leaves.
  SizedNode generate(int depth) {
    if (depth == 0) return ShapeNode(shape: .square(extent(4, 24)));

    return switch (random.nextInt(3)) {
      0 => BoxNode(padding: .all(4), children: children(depth)),
      1 => AlignNode(children: children(depth)),
      _ => flex(depth),
    };
  }

  /// A [FlexNode] along a random axis, whose container children are all
  /// flexed.
  ///
  /// That one rule is what keeps generation simple. A flexed child is
  /// measured against a finite slice of the main axis, so every container in
  /// the tree ends up with bounded constraints, and every flex factor,
  /// alignment, and `MainAxisSize` below it is legal without a special case.
  /// Leaves are left unflexed - they ignore their constraints anyway - so
  /// both the flex and non-flex paths still get exercised.
  FlexNode flex(int depth) {
    final items = children(depth);

    for (final item in items) {
      if (item is LayoutNode) {
        item.flex = .flexible(1 + random.nextInt(3));
      }
    }

    return FlexNode(
      direction: random.nextBool() ? .horizontal : .vertical,
      mainAxisAlignment: .values[random.nextInt(MainAxisAlignment.values.length)],
      crossAxisAlignment: .values[random.nextInt(CrossAxisAlignment.values.length)],
      children: items,
    );
  }

  /// Between one and [breadth] subtrees, one level shallower.
  List<Node> children(int depth) =>
      List.generate(1 + random.nextInt(breadth), (_) => generate(depth - 1));

  /// A random extent in `[min, max)`.
  double extent(double min, double max) => min + random.nextDouble() * (max - min);
}

Future<void> main() async {
  await runBenchmark(LayoutBenchmark());
}
