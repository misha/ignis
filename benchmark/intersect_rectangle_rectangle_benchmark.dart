import 'dart:math';

import 'package:ignis/ignis.dart';

import 'support/intersection_benchmark.dart';
import 'runner.dart';

class IntersectRectangleRectangleBenchmark extends IntersectionBenchmark {
  final double minSize;
  final double maxSize;
  final double range;

  IntersectRectangleRectangleBenchmark({
    super.seed,
    super.count,
    this.minSize = 10,
    this.maxSize = 40,
    this.range = 50,
  }) : super('Intersect Rectangle-Rectangle');

  @override
  IntersectionTest generate(Random random) {
    final sizeA = minSize + random.nextDouble() * (maxSize - minSize);
    final sizeB = minSize + random.nextDouble() * (maxSize - minSize);

    return IntersectionTest(
      shapeA: .rectangle,
      shapeB: .rectangle,
      boundsA: Aabb2.centerAndHalfExtents(
        .new((random.nextDouble() - 0.5) * range, (random.nextDouble() - 0.5) * range),
        .new(sizeA / 2, sizeA / 2),
      ),
      boundsB: Aabb2.centerAndHalfExtents(
        .new((random.nextDouble() - 0.5) * range, (random.nextDouble() - 0.5) * range),
        .new(sizeB / 2, sizeB / 2),
      ),
    );
  }
}

Future<void> main() async {
  await runBenchmark(IntersectRectangleRectangleBenchmark());
}
