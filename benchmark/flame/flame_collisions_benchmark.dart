// ignore_for_file: invalid_use_of_internal_member

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:flame/collisions.dart';
import 'package:flame/components.dart';
import 'package:flame/game.dart';

import '../support/collision_layout.dart';
import '../runner.dart';

const _WALL_THICKNESS = 10.0;

enum _Axis {
  x,
  y,
}

/// Flame version of `CollisionsBenchmark`, with matching parameters.
class FlameCollisionsBenchmark extends AsyncBenchmarkBase {
  final int seed;
  final int count;
  final int ticks;
  final double bounds;
  final double minSize;
  final double maxSize;
  final double speed;

  late final _CollisionGame _game;

  FlameCollisionsBenchmark({
    this.seed = 12345,
    this.count = 500,
    this.ticks = 100,
    this.bounds = 2000,
    this.minSize = 10,
    this.maxSize = 40,
    this.speed = 100,
  }) : super('(Flame) Collisions');

  @override
  Future<void> setup() async {
    _game = _CollisionGame();
    _game.onGameResize(Vector2(800, 600));
    await _game.load();
    _game.mount();
    _game.update(0);

    final layout = generateCollisionLayout(
      seed: seed,
      count: count,
      bounds: bounds,
      minSize: minSize,
      maxSize: maxSize,
      speed: speed,
    );

    final half = bounds / 2;
    final span = bounds + _WALL_THICKNESS * 2;
    final balls = [
      for (final entry in layout)
        _Ball(
          position: Vector2(entry.x, entry.y),
          velocity: Vector2(entry.vx, entry.vy),
          children: [
            switch (entry.shape) {
              .circle => CircleHitbox(
                collisionType: .active,
                radius: entry.size / 2,
              ),
              .square => RectangleHitbox(
                collisionType: .active,
                size: Vector2(entry.size, entry.size),
              ),
            },
          ],
        ),
    ];

    final walls = [
      _Wall(
        position: Vector2(-span / 2, -half - _WALL_THICKNESS),
        axis: .y,
        children: [
          RectangleHitbox(
            collisionType: .passive,
            size: Vector2(span, _WALL_THICKNESS),
          ),
        ],
      ),
      _Wall(
        position: Vector2(-span / 2, half),
        axis: .y,
        children: [
          RectangleHitbox(
            collisionType: .passive,
            size: Vector2(span, _WALL_THICKNESS),
          ),
        ],
      ),
      _Wall(
        position: Vector2(-half - _WALL_THICKNESS, -span / 2),
        axis: .x,
        children: [
          RectangleHitbox(
            collisionType: .passive,
            size: Vector2(_WALL_THICKNESS, span),
          ),
        ],
      ),
      _Wall(
        position: Vector2(half, -span / 2),
        axis: .x,
        children: [
          RectangleHitbox(
            collisionType: .passive,
            size: Vector2(_WALL_THICKNESS, span),
          ),
        ],
      ),
    ];

    await _game.addAll(balls);
    await _game.addAll(walls);
    await _game.ready();
  }

  @override
  Future<void> run() async {
    for (var t = 0; t < ticks; t += 1) {
      _game.update(1 / 60);
    }
  }
}

class _Wall extends PositionComponent {
  final _Axis axis;

  _Wall({
    required super.position,
    required this.axis,
    required super.children,
  });
}

/// Diverges slightly from the Ignis ball node in that it does not track the
/// the number of active collisions; [CollisionCallbacks] does it for you in
/// the `super` implementations of each callback.
class _Ball extends PositionComponent with CollisionCallbacks {
  final Vector2 velocity;

  _Ball({
    required super.position,
    required super.children,
    required this.velocity,
  });

  @override
  void update(double dt) {
    position.x += velocity.x * dt;
    position.y += velocity.y * dt;
  }

  @override
  void onCollisionStart(Set<Vector2> intersectionPoints, PositionComponent other) {
    super.onCollisionStart(intersectionPoints, other);

    switch (other) {
      case _Wall(:final axis):
        switch (axis) {
          case .x:
            velocity.x *= -1;

          case .y:
            velocity.y *= -1;
        }
    }
  }
}

class _CollisionGame extends FlameGame with HasCollisionDetection {
  // Nothing special.
}

Future<void> main() async {
  await runBenchmark(FlameCollisionsBenchmark());
}
