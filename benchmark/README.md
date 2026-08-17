## Benchmarks

Its own Flutter project, so a benchmark can be run three ways:

```bash
./bench.sh                  # every benchmark, under `flutter test`
./bench.sh update           # just that one
./bench.sh -p update        # under the VM's CPU sampling profiler
./bench.sh -r update        # compiled to a release binary, then run
./bench.sh -r flame_update  # the Flame comparison, same way
```

A bare name resolves to `<name>_benchmark.dart`, or to the same under `flame/`.

## Measurements

> :warning: This is not the performance tuning log and does not explain changes.

Measured with `flutter test` on 2026/08/17, average of 3 or more runs.

| Benchmark                     | Runtime     |
|-------------------------------|-------------|
| Collisions                    | 7365.83 us  |
| Intersect Circle-Circle       | 2132.50 us  |
| Intersect Circle-Rectangle    | 14677.91 us |
| Intersect Rectangle-Rectangle | 9394.30 us  |
| Layout                        | 23804.14 us |
| Lifecycle Events              | 45688.34 us |
| Nearest                       | 6861.46 us  |
| Signal Emissions              | 2535.51 us  |
| Update                        | 15781.22 us |
| Update + Render               | 34228.27 us |

System details:

- CPU: AMD Ryzen 7 9700X (8 cores / 16 threads)
- Memory: 59 GiB
- OS: Ubuntu 26.04 LTS, Linux 7.0.0-29-generic
- Flutter 3.47.0 (stable) • Dart 3.13.0

## Disclaimers

- Tests are executed with `flutter test`, so it's expected that actual performance is slightly different. Unfortunately, it is extraordinarily annoying to set up benchmarks for a Flutter library using `flutter run`.
- Some tests have a Flame version (see `flame/`), but Ignis and Flame are not strictly compatible so comparing their performance is apples-to-oranges. Nonetheless, it is useful to the maintainer to have a general sense of what Flame is capable of using the exact same environment.
