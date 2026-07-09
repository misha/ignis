// ignore_for_file: invalid_use_of_internal_member

import 'dart:ui';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../runner.dart';

/// Flame version of `UpdateRenderBenchmark`, with matching parameters.
class FlameUpdateRenderBenchmark extends AsyncBenchmarkBase {
  final int components;
  final int ticks;
  final int children;

  late final FlameGame game;

  FlameUpdateRenderBenchmark({
    this.components = 100,
    this.ticks = 100,
    this.children = 10,
  }) : super('(Flame) Update + Render');

  @override
  Future<void> setup() async {
    game = FlameGame();
    game.onGameResize(Vector2(800, 600));
    await game.load();
    game.mount();
    game.update(0);

    for (var i = 0; i < components; i += 1) {
      final component = RectangleComponent(size: Vector2(2, 2));

      for (var j = 0; j < children; j += 1) {
        component.add(RectangleComponent(size: Vector2(2, 2)));
      }

      game.add(component);
    }

    await game.ready();
  }

  @override
  Future<void> run() async {
    for (var t = 0; t < ticks; t += 1) {
      game.update(1 / 60);
      final recorder = PictureRecorder();
      game.render(Canvas(recorder));
      recorder.endRecording();
    }
  }
}

Future<void> main() async {
  await runBenchmark(FlameUpdateRenderBenchmark());
}
