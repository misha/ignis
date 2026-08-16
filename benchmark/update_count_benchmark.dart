import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// `UpdateBenchmark`'s tree (see `update_benchmark.dart`), except every node
/// counts the ticks it sees.
///
/// The smallest per-node work there is, with the count held in a
/// [Node.fuseState] slot so the score carries one hook lookup per node per
/// tick. The Flame version does the same count with a plain field.
///
/// Keep parameters in sync with `FlameUpdateCountBenchmark`.
class UpdateCountBenchmark extends AsyncBenchmarkBase {
  final int nodes;
  final int ticks;
  final int children;

  late Scene<Node> scene;

  UpdateCountBenchmark({
    this.nodes = 1000,
    this.ticks = 500,
    this.children = 10,
  }) : super('Update Count');

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
  @override
  void tick(double dt) {
    final count = fuseState(0);
    count.value += 1;
  }
}

Future<void> main() async {
  await runBenchmark(UpdateCountBenchmark());
}
