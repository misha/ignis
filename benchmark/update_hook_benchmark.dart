import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// `UpdateBenchmark`'s tree (see `update_benchmark.dart`), except every node
/// declares one hook that does its work once and nothing thereafter.
///
/// The content of the hook is beside the point; what this prices is the
/// *check* — walking a slot to keep the cursor aligned, on every node, on
/// every frame, for a hook that has nothing left to do. Whatever this scores
/// over `UpdateBenchmark` is that check.
///
/// Keep parameters in sync with `FlameUpdateHookBenchmark`.
class UpdateHookBenchmark extends AsyncBenchmarkBase {
  final int nodes;
  final int ticks;
  final int children;

  late Scene<Node> scene;

  UpdateHookBenchmark({
    this.nodes = 1000,
    this.ticks = 500,
    this.children = 10,
  }) : super('Update Hook');

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
  int wired = 0;

  @override
  void tick(double dt) {
    fuseEffect(() {
      wired += 1;
      return null;
    }, const []);
  }
}

Future<void> main() async {
  await runBenchmark(UpdateHookBenchmark());
}
