// ignore_for_file: invalid_use_of_internal_member

import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../runner.dart';

/// Flame version of `LifecycleEventsBenchmark`, with matching parameters.
class FlameLifecycleEventsBenchmark extends AsyncBenchmarkBase {
  final int seed;
  final int components;
  final int ticks;
  final int addsPerTick;
  final int removesPerTick;
  final int repositionsPerTick;
  final Random random;

  late final FlameGame game;
  late final List<Component> leaves;

  FlameLifecycleEventsBenchmark({
    this.seed = 12345,
    this.components = 500,
    this.ticks = 1000,
    this.addsPerTick = 20,
    this.removesPerTick = 20,
    this.repositionsPerTick = 20,
  }) : random = Random(seed),
       super('(Flame) Lifecycle Events');

  @override
  Future<void> setup() async {
    game = FlameGame();
    game.onGameResize(Vector2(800, 600));
    await game.load();
    game.mount();
    game.update(0);

    // Captured directly from the generated list rather than read back from
    // game.children afterward, since the latter also includes FlameGame's
    // own internal world/camera components.
    final initial = List.generate(components, (_) => Component());
    await game.addAll(initial);
    await game.ready();
    leaves = initial;
  }

  @override
  Future<void> run() async {
    for (var tick = 0; tick < ticks; tick += 1) {
      for (var i = 0; i < removesPerTick; i += 1) {
        final index = random.nextInt(leaves.length);
        final victim = leaves[index];

        game.remove(victim);
        final last = leaves.removeLast();
        if (index < leaves.length) leaves[index] = last;
      }

      for (var i = 0; i < addsPerTick; i += 1) {
        final fresh = Component();
        game.add(fresh);
        leaves.add(fresh);
      }

      for (var i = 0; i < repositionsPerTick; i += 1) {
        leaves[random.nextInt(leaves.length)].priority = random.nextInt(components);
      }

      game.update(1 / 60);
    }
  }
}

Future<void> main() async {
  await runBenchmark(FlameLifecycleEventsBenchmark());
}
