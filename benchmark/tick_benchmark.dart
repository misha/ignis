// ignore_for_file: invalid_use_of_internal_member

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// `UpdateBenchmark`'s tree (see `update_benchmark.dart`), except every node
/// counts the frames it sees under [Update].
///
/// The smallest per-node work there is, so whatever this scores over `Update`
/// is the cost of a tick.
///
/// Keep parameters in sync with `FlameTickBenchmark`.
class TickBenchmark extends AsyncBenchmarkBase {
  final int entities;
  final int ticks;
  final int children;

  late Scene scene;

  TickBenchmark({
    this.entities = 1000,
    this.ticks = 500,
    this.children = 10,
  }) : super('Tick');

  @override
  Future<void> setup() async {
    final root = Entity();

    for (var i = 0; i < entities; i += 1) {
      final entity = CounterEntity();

      for (var j = 0; j < children; j += 1) {
        entity.add(CounterEntity());
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

class CounterEntity extends Entity {
  int count = 0;

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Update():
        count += 1;
    }
  }
}

Future<void> main() async {
  await runBenchmark(TickBenchmark());
}
