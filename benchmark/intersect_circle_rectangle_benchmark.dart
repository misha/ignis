import 'dart:math';

import 'package:ignis/ignis.dart';

import 'support/intersection_benchmark.dart';
import 'runner.dart';

class IntersectCircleRectangleBenchmark extends IntersectionBenchmark {
  final double minSize;
  final double maxSize;
  final double range;

  IntersectCircleRectangleBenchmark({
    super.seed,
    super.count,
    this.minSize = 10,
    this.maxSize = 40,
    this.range = 50,
  }) : super('Intersect Circle-Rectangle');

  @override
  IntersectionTest generate(Random random) {
    final radius = (minSize + random.nextDouble() * (maxSize - minSize)) / 2;
    final size = minSize + random.nextDouble() * (maxSize - minSize);

    return IntersectionTest(
      shapeA: .circle,
      shapeB: .rectangle,
      boundsA: Aabb2.centerAndHalfExtents(
        .new((random.nextDouble() - 0.5) * range, (random.nextDouble() - 0.5) * range),
        .new(radius, radius),
      ),
      boundsB: Aabb2.centerAndHalfExtents(
        .new((random.nextDouble() - 0.5) * range, (random.nextDouble() - 0.5) * range),
        .new(size / 2, size / 2),
      ),
    );
  }
}

Future<void> main() async {
  await runBenchmark(IntersectCircleRectangleBenchmark());
}
