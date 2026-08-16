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

### Three extra fields on Node — no effect

The hook machinery puts `_hooks`, `_updates`, and `_cursor` on every node, and
Dart cannot drop fields under `kDebugMode`. Three more `int` fields were added
and written from `_rebuild` so they could not be shaken out, to price what that
costs the tree walk.

| Benchmark | Release baseline | Release +3 fields |
|-----------|------------------|-------------------|
| Update    | 41302.76 us      | 39917.41 us       |

-3.4%, against run spreads of 4.9% and 6.8%. Node's field count does not move
traversal at this size.

### Gating the hook machinery behind kDebugMode — reverted

`Scene.reassemble` returned early outside debug, `Node.fuse` skipped slot
matching (without reassembly a node builds once, so every pass appends), and
`SceneWidget` stopped listening to `Ignis.cache`. The two are coupled: matching
can only be dropped if a second pass is impossible.

| Benchmark      | Release ungated | Release gated |
|----------------|-----------------|---------------|
| Update         | 41302.76 us     | 41863.54 us   |
| Update Count   | 65793.31 us     | 65518.70 us   |
| Update Count 2 | 74023.55 us     | 74032.22 us   |

+1.4%, -0.4%, +0.0%. The machinery already took zero profiler samples, so
there was nothing on the frame path to remove; gating it saves binary size
only.

### Drift between release sessions

Unmodified code, measured twice in separate build-and-run sessions on the same
machine:

| Benchmark      | First       | Second      | Drift |
|----------------|-------------|-------------|-------|
| Update         | 39367.81 us | 41302.76 us | +4.9% |
| Update Count   | 67267.77 us | 65793.31 us | -2.2% |
| Update Count 2 | 77017.95 us | 74023.55 us | -3.9% |

Spread within a single session was 0.9-2.1%. Release deltas under ~5% across
sessions are not evidence.
