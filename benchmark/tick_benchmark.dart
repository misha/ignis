// ignore_for_file: invalid_use_of_internal_member

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// `UpdateBenchmark`'s tree (see `update_benchmark.dart`), except every node
/// registers one [Node.tick] that counts the frames it sees.
///
/// The smallest per-node work there is, so whatever this scores over `Update`
/// is the cost of a tick.
///
/// Keep parameters in sync with `FlameTickBenchmark`.
class TickBenchmark extends AsyncBenchmarkBase {
  final int nodes;
  final int ticks;
  final int children;

  late Scene<Node> scene;

  TickBenchmark({
    this.nodes = 1000,
    this.ticks = 500,
    this.children = 10,
  }) : super('Tick');

  @override
  Future<void> setup() async {
    final root = Node();

    for (var i = 0; i < nodes; i += 1) {
      final node = CounterNode();

      for (var j = 0; j < children; j += 1) {
        node.add(CounterNode());
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

class CounterNode extends Node {
  int count = 0;

  @override
  void build() {
    super.build();

    tick((_) {
      count += 1;
    });
  }
}

Future<void> main() async {
  await runBenchmark(TickBenchmark());
}
