import 'dart:math';

enum CollisionLayoutShape {
  square,
  circle,
}

/// A single shape/position/velocity triple, used to build equivalent
/// collision fixtures across different collision-system benchmarks.
class CollisionLayoutEntry {
  final CollisionLayoutShape shape;
  final double x;
  final double y;
  final double vx;
  final double vy;
  final double size;

  const CollisionLayoutEntry({
    required this.shape,
    required this.x,
    required this.y,
    required this.vx,
    required this.vy,
    required this.size,
  });
}

/// Generates [count] circles and squares, scattered uniformly at random
/// across a `[-bounds / 2, bounds / 2]` square, each moving at [speed] in a
/// random direction.
///
/// Deterministic for a given [seed], so callers building fixtures for
/// different collision systems can share the exact same layout and motion.
List<CollisionLayoutEntry> generateCollisionLayout({
  required int seed,
  required int count,
  required double bounds,
  required double minSize,
  required double maxSize,
  double speed = 100,
}) {
  final random = Random(seed);

  return List.generate(count, (i) {
    final size = minSize + random.nextDouble() * (maxSize - minSize);
    final angle = random.nextDouble() * 2 * pi;

    return CollisionLayoutEntry(
      shape: CollisionLayoutShape.values[random.nextInt(CollisionLayoutShape.values.length)],
      x: (random.nextDouble() - 0.5) * bounds,
      y: (random.nextDouble() - 0.5) * bounds,
      vx: cos(angle) * speed,
      vy: sin(angle) * speed,
      size: size,
    );
  });
}
