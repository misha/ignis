## Experiments

Things tried against the benchmarks and what they measured, kept so they are
not tried twice. Averages of 3 runs, `./bench.sh` and `./bench.sh -r`, same
machine and session within each entry.

### Freezing the update list — reverted

`Node._updates` is filled during a `build` pass and only read on the frames
after it, so the pass ended by replacing the growable list with a fixed-length
copy:

```dart
_updates = updates.isEmpty ? null : .of(updates, growable: false);
```

| Benchmark      | Test growable | Test frozen | Release growable | Release frozen |
|----------------|---------------|-------------|------------------|----------------|
| Update         | 18388.16 us   | 20469.58 us | 41302.76 us      | 39899.84 us    |
| Update Count   | 46582.12 us   | 45429.52 us | 65793.31 us      | 78995.35 us    |
| Update Count 2 | 59658.82 us   | 54937.82 us | 74023.55 us      | 96558.56 us    |

Test gained 2.5% and 7.9% on the two hook rows. Release lost 20.1% and 30.4% on
the same rows. Reverting restored the release numbers, so the change is the
cause rather than drift; run-to-run spread was 0.9–4.9%.
