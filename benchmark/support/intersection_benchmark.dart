import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

/// One shape/bounds pair for an [IntersectionBenchmark] to test.
class IntersectionTest {
  final Shape shapeA;
  final Shape shapeB;
  final Aabb2 boundsA;
  final Aabb2 boundsB;

  const IntersectionTest({
    required this.shapeA,
    required this.shapeB,
    required this.boundsA,
    required this.boundsB,
  });

  /// The same test with the a/b sides swapped.
  IntersectionTest swap() => IntersectionTest(
    shapeA: shapeB,
    shapeB: shapeA,
    boundsA: boundsB,
    boundsB: boundsA,
  );
}

abstract class IntersectionBenchmark extends AsyncBenchmarkBase {
  final int seed;
  final int count;

  final _system = StandardIntersectionSystem();
  final List<IntersectionTest> _tests = [];

  IntersectionBenchmark(
    super.name, {
    int? seed,
    int? count,
  }) : assert(count == null || count > 0),
       seed = seed ?? 12345,
       count = count ?? 200000;

  IntersectionTest generate(Random random);

  @override
  Future<void> setup() async {
    final random = Random(seed);

    for (var i = 0; i < count; i += 1) {
      var test = generate(random);
      if (random.nextBool()) test = test.swap();
      _tests.add(test);
    }
  }

  @override
  Future<void> run() async {
    var hits = 0;

    for (final test in _tests) {
      final hit = switch ((test.shapeA, test.shapeB)) {
        (.rectangle, .rectangle) => _system.rectangleRectangle(test.boundsA, test.boundsB),
        (.circle, .circle) => _system.circleCircle(test.boundsA, test.boundsB),
        (.circle, .rectangle) => _system.circleRectangle(test.boundsA, test.boundsB),
        (.rectangle, .circle) => _system.circleRectangle(test.boundsB, test.boundsA),
      };

      if (hit) hits += 1;
    }

    final rate = hits / count;
    if (rate < 0.1 || rate > 0.9) throw StateError('degenerate hit rate: $rate');
  }
}
