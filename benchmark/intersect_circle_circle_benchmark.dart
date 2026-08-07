import 'dart:math';

import 'support/intersection_benchmark.dart';
import 'runner.dart';

class IntersectCircleCircleBenchmark extends IntersectionBenchmark {
  final double minRadius;
  final double maxRadius;
  final double range;

  IntersectCircleCircleBenchmark({
    super.seed,
    super.count,
    this.minRadius = 5,
    this.maxRadius = 20,
    this.range = 50,
  }) : super('Intersect Circle-Circle');

  @override
  IntersectionTest generate(Random random) {
    final radiusA = minRadius + random.nextDouble() * (maxRadius - minRadius);
    final radiusB = minRadius + random.nextDouble() * (maxRadius - minRadius);

    return IntersectionTest(
      shapeA: .circle(radiusA),
      shapeB: .circle(radiusB),
      centerA: randomCenter(random, range),
      centerB: randomCenter(random, range),
    );
  }
}

Future<void> main() async {
  await runBenchmark(IntersectCircleCircleBenchmark());
}
