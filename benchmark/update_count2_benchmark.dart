import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// `UpdateCountBenchmark`'s tree (see `update_count_benchmark.dart`), except
/// every node counts twice over.
///
/// Doubling the closures rather than the nodes is what separates a tick
/// closure's one-time cost from its marginal one: whatever this scores over
/// the single-counter run is what a second [Node.tick] closure costs, per
/// node, per tick.
///
/// Keep parameters in sync with `FlameUpdateCount2Benchmark`.
class UpdateCount2Benchmark extends AsyncBenchmarkBase {
  final int nodes;
  final int ticks;
  final int children;

  late Scene<Node> scene;

  UpdateCount2Benchmark({
    this.nodes = 1000,
    this.ticks = 500,
    this.children = 10,
  }) : super('Update Count 2');

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
  int first = 0;
  int second = 0;

  @override
  void build() {
    tick << (_) {
      first += 1;
    };

    tick << (_) {
      second += 1;
    };

    super.build();
  }
}

Future<void> main() async {
  await runBenchmark(UpdateCount2Benchmark());
}
