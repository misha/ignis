import 'dart:async';

import 'package:ignis/ignis.dart';

/// A loader with no I/O: it records what it loaded, fails on demand, and can
/// hold an asset open until the test releases its gate.
final class TestLoader extends Loader {
  final List<String> loaded = [];
  final Set<String> failing = {};
  final Map<String, Completer<void>> gates = {};

  @override
  Future<void> load(LoadingContext context) async {
    if (failing.contains(context.asset)) {
      throw StateError('failed to load ${context.asset}');
    }

    final gate = gates[context.asset];
    if (gate != null) await gate.future;
    loaded.add(context.asset);
    context.cache.add(context.asset, context.asset);
  }
}
