// ignore_for_file: invalid_use_of_internal_member

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// `TickBenchmark`'s tree (see `tick_benchmark.dart`), except every node
/// registers two counting ticks instead of one.
///
/// Whatever this scores over `Tick` is the cost of a second registered
/// behavior on a node that already has one.
///
/// Keep parameters in sync with `TickBenchmark`.
class Tick2Benchmark extends AsyncBenchmarkBase {
  final int nodes;
  final int ticks;
  final int children;

  late Scene<Node> scene;

  Tick2Benchmark({
    this.nodes = 1000,
    this.ticks = 500,
    this.children = 10,
  }) : super('Tick 2');

  @override
  Future<void> setup() async {
    final root = Node();

    for (var i = 0; i < nodes; i += 1) {
      final node = DoubleCounterNode();

      for (var j = 0; j < children; j += 1) {
        node.add(DoubleCounterNode());
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

class DoubleCounterNode extends Node {
  int first = 0;
  int second = 0;

  @override
  void build() {
    super.build();

    tick((_) {
      first += 1;
    });

    tick((_) {
      second += 1;
    });
  }
}

Future<void> main() async {
  await runBenchmark(Tick2Benchmark());
}
