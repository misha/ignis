// ignore_for_file: invalid_use_of_internal_member

import 'dart:ui';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// Like `UpdateBenchmark` (see `update_benchmark.dart`), but each
/// tick also renders the tree to a real (headless) [Canvas]. The leaves are
/// [ShapeNode]s instead of bare [Node]s, so rendering the root issues an
/// actual draw call per node instead of just traversing.
///
/// Keep parameters in sync with `FlameUpdateRenderBenchmark`.
class UpdateRenderBenchmark extends AsyncBenchmarkBase {
  final int nodes;
  final int ticks;
  final int children;

  late final Scene<Node> scene;

  UpdateRenderBenchmark({
    this.nodes = 100,
    this.ticks = 100,
    this.children = 10,
  }) : super('Update + Render');

  @override
  Future<void> setup() async {
    final root = Node();

    for (var i = 0; i < nodes; i += 1) {
      final node = ShapeNode(shape: .square(2));

      for (var j = 0; j < children; j += 1) {
        node.add(ShapeNode(shape: .square(2)));
      }

      root.add(node);
    }

    scene = root.mount();
    scene.resize(800, 600);
  }

  @override
  Future<void> run() async {
    for (var t = 0; t < ticks; t += 1) {
      scene.update(1 / 60);
      final recorder = PictureRecorder();
      scene.render(Canvas(recorder));
      recorder.endRecording();
    }
  }

  @override
  Future<void> teardown() async => scene.destroy();
}

Future<void> main() async {
  await runBenchmark(UpdateRenderBenchmark());
}
