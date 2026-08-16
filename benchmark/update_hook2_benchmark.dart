import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// `UpdateHook2Benchmark`'s tree (see `update_hook_benchmark.dart`), except
/// every node declares two hooks rather than one.
///
/// Whatever this scores over the single-hook run is what a second slot check
/// costs, per node, per frame — which is what separates a hook's one-time
/// cost from its marginal one.
///
/// Keep parameters in sync with `FlameUpdateHook2Benchmark`.
class UpdateHook2Benchmark extends AsyncBenchmarkBase {
  final int nodes;
  final int ticks;
  final int children;

  late Scene<Node> scene;

  UpdateHook2Benchmark({
    this.nodes = 1000,
    this.ticks = 500,
    this.children = 10,
  }) : super('Update Hook 2');

  @override
  Future<void> setup() async {
    final root = Node();

    for (var i = 0; i < nodes; i += 1) {
      final node = HookNode();

      for (var j = 0; j < children; j += 1) {
        node.add(HookNode());
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

class HookNode extends Node {
  int first = 0;
  int second = 0;

  @override
  void tick(double dt) {
    fuseEffect(() {
      first += 1;
      return null;
    }, const []);

    fuseEffect(() {
      second += 1;
      return null;
    }, const []);
  }
}

Future<void> main() async {
  await runBenchmark(UpdateHook2Benchmark());
}
