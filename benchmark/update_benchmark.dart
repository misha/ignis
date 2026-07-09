// ignore_for_file: invalid_use_of_internal_member

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// A wide, shallow tree of empty nodes, driven by [ticks] update ticks.
///
/// Pure traversal cost: no vector math, no simulated input, no benchmark-only
/// subclass, just plain nodes, each set up with its own children before
/// being added to the root.
///
/// Keep parameters in sync with `FlameUpdateBenchmark`.
class UpdateBenchmark extends AsyncBenchmarkBase {
  final int nodes;
  final int ticks;
  final int children;

  late Scene<Node> scene;

  UpdateBenchmark({
    this.nodes = 1000,
    this.ticks = 500,
    this.children = 10,
  }) : super('Update');

  @override
  Future<void> setup() async {
    final root = Node();

    for (var i = 0; i < nodes; i += 1) {
      final node = Node();

      for (var j = 0; j < children; j += 1) {
        node.add(Node());
      }

      root.add(node);
    }

    scene = root.mount();
  }

  @override
  Future<void> run() async {
    for (var t = 0; t < ticks; t += 1) {
      scene.update(1 / 60);
    }
  }

  @override
  Future<void> teardown() async => scene.destroy();
}

Future<void> main() async {
  await runBenchmark(UpdateBenchmark());
}
