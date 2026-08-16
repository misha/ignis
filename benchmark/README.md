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

Measured on 2026/08/16 with `./bench.sh` and `./bench.sh -r`, average of 3 runs
each.

| Benchmark      | Test        | Release     |
|----------------|-------------|-------------|
| Update         | 20715.21 us | 41885.01 us |
| Update Count   | 46395.72 us | 65717.91 us |
| Update Count 2 | 59720.64 us | 74960.27 us |
| Update Count 3 | 73136.88 us | 86225.11 us |

System details:

- CPU: AMD Ryzen 7 9700X (8 cores / 16 threads)
- Memory: 59 GiB
- OS: Ubuntu 26.04 LTS, Linux 7.0.0-29-generic
- Flutter 3.47.0 (stable) • Dart 3.13.0

## Disclaimers

- The test column runs under `flutter test` (JIT, asserts on); the release column is an AOT binary.
- Some tests have a Flame version (see `flame/`), but Ignis and Flame are not strictly compatible so comparing their performance is apples-to-oranges. Nonetheless, it is useful to the maintainer to have a general sense of what Flame is capable of using the exact same environment.
