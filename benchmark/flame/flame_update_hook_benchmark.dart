// ignore_for_file: invalid_use_of_internal_member

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../runner.dart';

/// Flame version of `UpdateHookBenchmark`, with matching parameters.
///
/// Flame has no per-frame declaration to check, so the same one-time work goes
/// in `onMount` and this row is flat against `FlameUpdateBenchmark` by
/// construction. That flatness is the comparison.
class FlameUpdateHookBenchmark extends AsyncBenchmarkBase {
  final int components;
  final int ticks;
  final int children;

  late final FlameGame game;

  FlameUpdateHookBenchmark({
    this.components = 1000,
    this.ticks = 500,
    this.children = 10,
  }) : super('(Flame) Update Hook');

  @override
  Future<void> setup() async {
    game = FlameGame();
    game.onGameResize(Vector2(800, 600));
    await game.load();
    game.mount();
    game.update(0);

    for (var i = 0; i < components; i += 1) {
      final component = HookComponent();

      for (var j = 0; j < children; j += 1) {
        component.add(HookComponent());
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

class HookComponent extends Component {
  int wired = 0;

  @override
  void onMount() => wired += 1;
}

Future<void> main() async {
  await runBenchmark(FlameUpdateHookBenchmark());
}
