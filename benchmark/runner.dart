import 'dart:io';

import 'package:benchmark_harness/benchmark_harness.dart';

import 'profiler.dart';

/// Runs [benchmark] normally, unless the `PROFILE` environment variable is
/// set, in which case it's run under [profile] instead.
///
/// Use this in place of `benchmark.report()` in any benchmark's `main()`, so
/// profiling toggles on without editing the file:
///
/// ```dart
/// void main() async => await runBenchmark(UpdateBenchmark());
/// ```
///
/// Then, when executing:
///
/// ```sh
/// flutter test benchmark/your_benchmark.dart                              # normal
/// PROFILE=1 flutter test --enable-vmservice benchmark/your_benchmark.dart # profiled
/// ```
///
/// Profiling requires the VM service, hence `--enable-vmservice` — it's only
/// needed when `PROFILE` is actually set.
///
/// Benchmarks must extend [AsyncBenchmarkBase], not `BenchmarkBase`, as the
/// two report scores on different scales ([BenchmarkBase.exercise] secretly
/// runs 10 times per measured iteration, `AsyncBenchmarkBase.exercise` runs
/// once), so mixing them produces numbers that look comparable but aren't.
/// There's no synchronous counterpart here on purpose.
Future<void> runBenchmark(AsyncBenchmarkBase benchmark) async {
  if (Platform.environment.containsKey('PROFILE')) {
    await profile(benchmark);
  } else {
    await benchmark.report();
  }
}
