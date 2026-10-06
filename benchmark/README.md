## Benchmarks

Its own Flutter project, so a benchmark can be run three ways:

```bash
./bench.sh                  # every benchmark, under `flutter test`
./bench.sh update           # just that one
./bench.sh -p update        # under the VM's CPU sampling profiler
./bench.sh -r update        # compiled to a release binary, then run
```

A bare name resolves to `<name>_benchmark.dart`, or to the same under `flame/`.

## Measurements

> :warning: This is not the performance tuning log and does not explain changes.

Measured with `flutter test` on 2026/10/06, average of 3 or more runs.

| Benchmark                     | Runtime     |
|-------------------------------|-------------|
| Churn                         | 36264.32 us |
| Collisions                    | 8059.50 us  |
| Intersect Circle-Circle       | 2159.68 us  |
| Intersect Circle-Rectangle    | 15037.61 us |
| Intersect Rectangle-Rectangle | 9330.36 us  |
| Layout                        | 36446.80 us |
| Lifecycle Events              | 49310.04 us |
| Nearest                       | 9103.92 us  |
| Signal Emissions              | 2557.77 us  |
| Tick                          | 37917.16 us |
| Tick 2                        | 46698.60 us |
| Update                        | 15480.28 us |
| Update + Render               | 31074.31 us |

System details:

- CPU: AMD Ryzen 7 9700X (8 cores / 16 threads)
- Memory: 59 GiB
- OS: Ubuntu 26.04.1 LTS, Linux 7.0.0-38-generic
- Flutter 3.47.5 (stable) • Dart 3.13.4

## Flame Benchmarks

Some tests have a Flame version (see `flame/`), but Ignis and Flame are not strictly compatible so comparing their performance is apples-to-oranges. Nonetheless, it is sometimes useful to have a general sense of what Flame is capable of using the exact same environment.
