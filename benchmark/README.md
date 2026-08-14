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

Measured with `flutter test` on 2026/08/14, average of 3 or more runs.

| Benchmark                     | Runtime     |
|-------------------------------|-------------|
| Collisions                    | 6926.39 us  |
| Intersect Circle-Circle       | 2012.87 us  |
| Intersect Circle-Rectangle    | 14665.78 us |
| Intersect Rectangle-Rectangle | 9116.06 us  |
| Layout                        | 21543.87 us |
| Lifecycle Events              | 47056.24 us |
| Nearest                       | 6728.26 us  |
| Signal Emissions              | 2534.44 us  |
| Update                        | 15357.43 us |
| Update + Render               | 32887.69 us |

System details:

- CPU: AMD Ryzen 7 9700X (8 cores / 16 threads)
- Memory: 59 GiB
- OS: Ubuntu 26.04 LTS, Linux 7.0.0-29-generic
- Flutter 3.47.0 (stable) • Dart 3.13.0

## Disclaimers

- Tests are executed with `flutter test`, so it's expected that actual performance is slightly different. Unfortunately, it is extraordinarily annoying to set up benchmarks for a Flutter library using `flutter run`.
- Some tests have a Flame version (see `flame/`), but Ignis and Flame are not strictly compatible so comparing their performance is apples-to-oranges. Nonetheless, it is useful to the maintainer to have a general sense of what Flame is capable of using the exact same environment.
