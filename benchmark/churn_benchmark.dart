// ignore_for_file: invalid_use_of_internal_member

import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// Structural edits made mid-update to the very children being updated: each
/// world holds a spawner and its leaves, every leaf detaches itself when its
/// lifetime runs out, and the spawner refills the world from its own tick.
///
/// Lifetimes average 10 frames, so about a tenth of every world turns over
/// each tick.
///
/// Keep parameters in sync with `FlameChurnBenchmark`.
class ChurnBenchmark extends AsyncBenchmarkBase {
  final int seed;
  final int worlds;
  final int leaves;
  final int ticks;
  final int lifetime;
  final Random random;

  late Scene scene;

  ChurnBenchmark({
    this.seed = 12345,
    this.worlds = 50,
    this.leaves = 100,
    this.ticks = 100,
    this.lifetime = 19,
  }) : random = Random(seed),
       super('Churn');

  @override
  Future<void> setup() async {
    final root = Node();

    for (var i = 0; i < worlds; i += 1) {
      final world = Node();
      world.add(Spawner(this));

      for (var j = 0; j < leaves; j += 1) {
        world.add(spawn());
      }

      root.add(world);
    }

    scene = root.mount();
  }

  /// A leaf with a lifetime between 1 and [lifetime] frames.
  Leaf spawn() => Leaf(1 + random.nextInt(lifetime));

  @override
  Future<void> run() async {
    for (var tick = 0; tick < ticks; tick += 1) {
      scene.update(1 / 60);
    }
  }

  @override
  Future<void> teardown() async => scene.destroy();
}

/// Refills its parent to [ChurnBenchmark.leaves] leaves every frame, ticking
/// ahead of them.
class Spawner extends Node {
  final ChurnBenchmark benchmark;

  Spawner(this.benchmark) : super(priority: -1);

  @override
  void build() {
    super.build();

    tick((_) {
      final world = parent!;

      for (var i = world.query<Leaf>().length; i < benchmark.leaves; i += 1) {
        world.add(benchmark.spawn());
      }
    });
  }
}

/// Detaches itself once [remaining] frames have passed.
class Leaf extends Node {
  int remaining;

  Leaf(this.remaining);

  @override
  void build() {
    super.build();

    tick((_) {
      remaining -= 1;
      if (remaining == 0) detach();
    });
  }
}

Future<void> main() async {
  await runBenchmark(ChurnBenchmark());
}
