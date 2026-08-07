import 'dart:math';

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
      shapeA: .square(sizeA),
      shapeB: .square(sizeB),
      centerA: randomCenter(random, range),
      centerB: randomCenter(random, range),
    );
  }
}

Future<void> main() async {
  await runBenchmark(IntersectRectangleRectangleBenchmark());
}
