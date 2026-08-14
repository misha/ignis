import 'dart:math';

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

/// One shape/center pair for an [IntersectionBenchmark] to test.
class IntersectionTest {
  final Shape shapeA;
  final Shape shapeB;
  final Vector2 centerA;
  final Vector2 centerB;

  const IntersectionTest({
    required this.shapeA,
    required this.shapeB,
    required this.centerA,
    required this.centerB,
  });

  /// The same test with the a/b sides swapped.
  IntersectionTest swap() => IntersectionTest(
    shapeA: shapeB,
    shapeB: shapeA,
    centerA: centerB,
    centerB: centerA,
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

  /// A random point within `[-range / 2, range / 2)` on both axes.
  Vector2 randomCenter(Random random, double range) {
    final point = MVector2.copy(RandomVector2.random(random))
      ..subtract(.all(0.5))
      ..scale(range);

    return point;
  }

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
        (Rectangle a, Rectangle b) => _system.rectangleRectangle(
          test.centerA,
          _ex(a),
          _ey(a),
          test.centerB,
          _ex(b),
          _ey(b),
        ),
        (Circle a, Circle b) => _system.circleCircle(
          test.centerA,
          a.radius,
          test.centerB,
          b.radius,
        ),
        (Circle a, Rectangle b) => _system.circleRectangle(
          test.centerA,
          a.radius,
          test.centerB,
          _ex(b),
          _ey(b),
        ),
        (Rectangle a, Circle b) => _system.circleRectangle(
          test.centerB,
          b.radius,
          test.centerA,
          _ex(a),
          _ey(a),
        ),
      };

      if (hit) hits += 1;
    }

    final rate = hits / count;
    if (rate < 0.1 || rate > 0.9) throw StateError('degenerate hit rate: $rate');
  }

  /// [shape]'s (unrotated) half-extent vector along its right edge.
  Vector2 _ex(Rectangle shape) => Vector2(shape.size.x / 2, 0);

  /// [shape]'s (unrotated) half-extent vector along its bottom edge.
  Vector2 _ey(Rectangle shape) => Vector2(0, shape.size.y / 2);
}
