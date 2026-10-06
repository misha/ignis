// ignore_for_file: invalid_use_of_internal_member

import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../runner.dart';

/// Flame version of `ChurnBenchmark`, with matching parameters.
class FlameChurnBenchmark extends AsyncBenchmarkBase {
  final int seed;
  final int worlds;
  final int leaves;
  final int ticks;
  final int lifetime;
  final Random random;

  late final FlameGame game;

  FlameChurnBenchmark({
    this.seed = 12345,
    this.worlds = 50,
    this.leaves = 100,
    this.ticks = 100,
    this.lifetime = 19,
  }) : random = Random(seed),
       super('(Flame) Churn');

  @override
  Future<void> setup() async {
    game = FlameGame();
    game.onGameResize(Vector2(800, 600));
    await game.load();
    game.mount();
    game.update(0);

    for (var i = 0; i < worlds; i += 1) {
      final world = Component();

      // Cached like Ignis's query index, rather than filtered on every call.
      world.children.register<LeafComponent>();
      world.add(SpawnerComponent(this));

      for (var j = 0; j < leaves; j += 1) {
        world.add(spawn());
      }

      game.add(world);
    }

    await game.ready();
  }

  /// A leaf with a lifetime between 1 and [lifetime] frames.
  LeafComponent spawn() => LeafComponent(1 + random.nextInt(lifetime));

  @override
  Future<void> run() async {
    for (var tick = 0; tick < ticks; tick += 1) {
      game.update(1 / 60);
    }
  }
}

/// Refills its parent to [FlameChurnBenchmark.leaves] leaves every frame,
/// updating ahead of them.
class SpawnerComponent extends Component {
  final FlameChurnBenchmark benchmark;

  SpawnerComponent(this.benchmark) : super(priority: -1);

  @override
  void update(double dt) {
    final world = parent!;

    for (var i = world.children.query<LeafComponent>().length; i < benchmark.leaves; i += 1) {
      world.add(benchmark.spawn());
    }
  }
}

/// Removes itself once [remaining] frames have passed.
class LeafComponent extends Component {
  int remaining;

  LeafComponent(this.remaining);

  @override
  void update(double dt) {
    remaining -= 1;
    if (remaining == 0) removeFromParent();
  }
}

Future<void> main() async {
  await runBenchmark(FlameChurnBenchmark());
}
