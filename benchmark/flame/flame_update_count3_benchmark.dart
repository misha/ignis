// ignore_for_file: invalid_use_of_internal_member

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../runner.dart';

/// Flame version of `UpdateCount3Benchmark`, with matching parameters.
class FlameUpdateCount3Benchmark extends AsyncBenchmarkBase {
  final int components;
  final int ticks;
  final int children;

  late final FlameGame game;

  FlameUpdateCount3Benchmark({
    this.components = 1000,
    this.ticks = 500,
    this.children = 10,
  }) : super('(Flame) Update Count 3');

  @override
  Future<void> setup() async {
    game = FlameGame();
    game.onGameResize(Vector2(800, 600));
    await game.load();
    game.mount();
    game.update(0);

    for (var i = 0; i < components; i += 1) {
      final component = CounterComponent();

      for (var j = 0; j < children; j += 1) {
        component.add(CounterComponent());
      }

      game.add(component);
    }

    await game.ready();
  }

  @override
  Future<void> run() async {
    for (var t = 0; t < ticks; t += 1) {
      game.update(1 / 60);
    }
  }
}

class CounterComponent extends Component {
  int first = 0;
  int second = 0;
  int third = 0;

  @override
  void update(double dt) {
    first += 1;
    second += 1;
    third += 1;
  }
}

Future<void> main() async {
  await runBenchmark(FlameUpdateCount3Benchmark());
}
