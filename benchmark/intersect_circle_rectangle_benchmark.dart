import 'dart:math';

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
      shapeA: .circle(radius),
      shapeB: .square(size),
      centerA: randomCenter(random, range),
      centerB: randomCenter(random, range),
    );
  }
}

Future<void> main() async {
  await runBenchmark(IntersectCircleRectangleBenchmark());
}
