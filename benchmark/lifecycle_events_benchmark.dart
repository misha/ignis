import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// Steady-state per-tick add/remove/reposition churn against a live scene,
/// measuring structural mutation cost under realistic occupancy.
///
/// Keep parameters in sync with `FlameLifecycleEventsBenchmark`.
class LifecycleEventsBenchmark extends AsyncBenchmarkBase {
  final int seed;
  final int nodes;
  final int ticks;
  final int addsPerTick;
  final int removesPerTick;
  final int repositionsPerTick;
  final Random random;

  late Node root;
  late Scene<Node> scene;
  late List<Node> leaves;

  LifecycleEventsBenchmark({
    this.seed = 12345,
    this.nodes = 500,
    this.ticks = 1000,
    this.addsPerTick = 20,
    this.removesPerTick = 20,
    this.repositionsPerTick = 20,
  }) : random = Random(seed),
       super('Lifecycle Events');

  @override
  Future<void> setup() async {
    root = Node();
    root.addAll(List.generate(nodes, (_) => Node()));
    scene = root.mount();
    leaves = root.children.toList();
  }

  @override
  Future<void> run() async {
    for (var tick = 0; tick < ticks; tick += 1) {
      for (var i = 0; i < removesPerTick; i += 1) {
        final index = random.nextInt(leaves.length);
        final victim = leaves[index];

        root.remove(victim);
        final last = leaves.removeLast();
        if (index < leaves.length) leaves[index] = last;
      }

      for (var i = 0; i < addsPerTick; i += 1) {
        final fresh = Node();
        root.add(fresh);
        leaves.add(fresh);
      }

      for (var i = 0; i < repositionsPerTick; i += 1) {
        leaves[random.nextInt(leaves.length)].priority = random.nextInt(nodes);
      }

      scene.update(1 / 60);
    }
  }

  @override
  Future<void> teardown() async => scene.destroy();
}

Future<void> main() async {
  await runBenchmark(LifecycleEventsBenchmark());
}
