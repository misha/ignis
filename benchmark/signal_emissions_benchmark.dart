import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'runner.dart';

/// Steady-state [Signal1.emit] cost against a pool of watchers, with
/// occasional subscription churn mixed in.
class SignalEmissionsBenchmark extends AsyncBenchmarkBase {
  final int seed;
  final int watchers;
  final int emissions;
  final int churnPerEmission;
  final Random random;

  late final Signal1<int> _signal;
  late final List<Cleanup> _cleanups;
  int _sum = 0;

  SignalEmissionsBenchmark({
    this.seed = 12345,
    this.watchers = 100,
    this.emissions = 5000,
    this.churnPerEmission = 1,
  }) : random = Random(seed),
       super('Signal Emissions');

  Cleanup _watch() => _signal((a) => _sum += a);

  @override
  Future<void> setup() async {
    _signal = Signal1<int>();
    _cleanups = List.generate(watchers, (_) => _watch());
  }

  @override
  Future<void> run() async {
    for (var i = 0; i < emissions; i += 1) {
      for (var c = 0; c < churnPerEmission; c += 1) {
        final index = random.nextInt(_cleanups.length);
        _cleanups[index]();
        _cleanups[index] = _watch();
      }

      _signal.emit(i);
    }
  }
}

Future<void> main() async {
  await runBenchmark(SignalEmissionsBenchmark());
}
