## Benchmarks

Run a benchmark:

```bash
flutter test benchmark/update_benchmark.dart
```

Run a specific benchmark with profiling enabled:

```bash
PROFILE=1 flutter test --enable-vmservice benchmark/update_benchmark.dart
```

## Measurements

> :warning: This is not the performance tuning log and does not explain changes.

Measured with `flutter test` on 2026/08/05, average of 3 runs.

| Benchmark                     | Runtime     |
|-------------------------------|-------------|
| Collisions                    | 6828.51 us  |
| Intersect Circle-Circle       | 4226.79 us  |
| Intersect Circle-Rectangle    | 14408.45 us |
| Intersect Rectangle-Rectangle | 3993.47 us  |
| Lifecycle Events              | 43840.39 us |
| Signal Emissions              | 2607.56 us  |
| Update                        | 15350.79 us |
| Update + Render               | 31019.50 us |

System details:

- CPU: AMD Ryzen 7 9700X (8 cores / 16 threads)
- Memory: 59 GiB
- OS: Ubuntu 26.04 LTS, Linux 7.0.0-28-generic
- Flutter 3.44.8 (stable) • Dart 3.12.2

## Disclaimers

- Tests are executed with `flutter test`, so it's expected that actual performance is slightly different. Unfortunately, it is extraordinarily annoying to set up benchmarks for a Flutter library using `flutter run`.
- Some tests have a Flame version (see `flame/`), but Ignis and Flame are not strictly compatible so comparing their performance is an apples-to-oranges. Nonetheless, it is useful to the maintainer to have a general sense of what Flame is capable of using the exact same environment.
