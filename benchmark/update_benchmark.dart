// ignore_for_file: invalid_use_of_internal_member

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// A wide, shallow tree of empty nodes, driven by [ticks] update ticks.
///
/// Pure traversal cost: plain nodes, each given its children before being
/// added to the root.
///
/// Keep parameters in sync with `FlameUpdateBenchmark`.
class UpdateBenchmark extends AsyncBenchmarkBase {
  final int entities;
  final int ticks;
  final int children;

  late Scene scene;

  UpdateBenchmark({
    this.entities = 1000,
    this.ticks = 500,
    this.children = 10,
  }) : super('Update');

  @override
  Future<void> setup() async {
    final root = Entity();

    for (var i = 0; i < entities; i += 1) {
      final entity = Entity();

      for (var j = 0; j < children; j += 1) {
        entity.add(Entity());
      }

      root.add(entity);
    }

    scene = Scene(root);
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
