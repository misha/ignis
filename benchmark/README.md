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

Measured with `flutter test` on 2026/08/26, average of 3 or more runs.

| Benchmark                     | Runtime     |
|-------------------------------|-------------|
| Collisions                    | 7721.87 us  |
| Intersect Circle-Circle       | 2122.28 us  |
| Intersect Circle-Rectangle    | 14451.17 us |
| Intersect Rectangle-Rectangle | 9262.52 us  |
| Layout                        | 23755.91 us |
| Lifecycle Events              | 46558.53 us |
| Nearest                       | 9161.10 us  |
| Signal Emissions              | 2563.62 us  |
| Update                        | 16015.22 us |
| Update + Render               | 31606.76 us |

System details:

- CPU: AMD Ryzen 7 9700X (8 cores / 16 threads)
- Memory: 59 GiB
- OS: Ubuntu 26.04 LTS, Linux 7.0.0-30-generic
- Flutter 3.47.0 (stable) • Dart 3.13.0

## Flame Benchmarks

Some tests have a Flame version (see `flame/`), but Ignis and Flame are not strictly compatible so comparing their performance is apples-to-oranges. Nonetheless, it is sometimes useful to have a general sense of what Flame is capable of using the exact same environment.
