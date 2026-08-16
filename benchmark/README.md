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

Measured with `flutter test` on 2026/08/16, average of 3 or more runs.

| Benchmark      | Runtime     |
|----------------|-------------|
| Update         | 19821.51 us |
| Update Count   | 47065.32 us |
| Update Count 2 | 59245.41 us |

System details:

- CPU: AMD Ryzen 7 9700X (8 cores / 16 threads)
- Memory: 59 GiB
- OS: Ubuntu 26.04 LTS, Linux 7.0.0-29-generic
- Flutter 3.47.0 (stable) • Dart 3.13.0

## Disclaimers

- Tests are executed with `flutter test`, so it's expected that actual performance is slightly different. Unfortunately, it is extraordinarily annoying to set up benchmarks for a Flutter library using `flutter run`.
- Some tests have a Flame version (see `flame/`), but Ignis and Flame are not strictly compatible so comparing their performance is apples-to-oranges. Nonetheless, it is useful to the maintainer to have a general sense of what Flame is capable of using the exact same environment.
