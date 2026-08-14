// ignore_for_file: invalid_use_of_internal_member

import 'package:benchmark_harness/benchmark_harness.dart';
import 'package:ignis/ignis.dart';

import 'support/collision_layout.dart';
import 'runner.dart';

const _WALL_LAYER = 1 << 0;
const _BALL_LAYER = 1 << 1;
const _WALL_THICKNESS = 10.0;

enum _Axis {
  x,
  y,
}

/// Steps a [CollisionDetectionNode] full of shapes bouncing around a walled box.
///
/// Keep parameters in sync with `FlameCollisionsBenchmark`.
class CollisionsBenchmark extends AsyncBenchmarkBase {
  final int seed;
  final int count;
  final int ticks;
  final double bounds;
  final double minSize;
  final double maxSize;
  final double speed;

  late Scene<CollisionDetectionNode> scene;

  CollisionsBenchmark({
    this.seed = 12345,
    this.count = 500,
    this.ticks = 100,
    this.bounds = 2000,
    this.minSize = 10,
    this.maxSize = 40,
    this.speed = 100,
  }) : super('Collisions');

  @override
  Future<void> setup() async {
    final root = CollisionDetectionNode();
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

    for (final entry in layout) {
      root.add(
        _Ball(
          shape: switch (entry.shape) {
            .circle => .circle(entry.size / 2),
            .square => .square(entry.size),
          },
          position: .new(entry.x, entry.y),
          velocity: .new(entry.vx, entry.vy),
        ),
      );
    }

    root.addAll([
      _Wall(
        shape: .rectangle(.new(span, _WALL_THICKNESS)),
        position: .new(0, -half - _WALL_THICKNESS / 2),
        axis: .y,
      ),
      _Wall(
        shape: .rectangle(.new(span, _WALL_THICKNESS)),
        position: .new(0, half + _WALL_THICKNESS / 2),
        axis: .y,
      ),
      _Wall(
        shape: .rectangle(.new(_WALL_THICKNESS, span)),
        position: .new(-half - _WALL_THICKNESS / 2, 0),
        axis: .x,
      ),
      _Wall(
        shape: .rectangle(.new(_WALL_THICKNESS, span)),
        position: .new(half + _WALL_THICKNESS / 2, 0),
        axis: .x,
      ),
    ]);

    scene = root.mount();
  }

  @override
  Future<void> run() async {
    for (var t = 0; t < ticks; t += 1) {
      scene.update(1 / 60);
    }
  }

  @override
  Future<void> teardown() async => scene.destroy();
}

class _Wall extends TransformNode {
  final _Axis axis;

  _Wall({
    required Shape shape,
    required this.axis,
    required super.position,
  }) {
    add(
      ColliderNode(
        shape: shape,
        anchor: .center,
        layer: _WALL_LAYER,
      ),
    );
  }
}

class _Ball extends TransformNode {
  final MVector2 velocity;
  int balls = 0;

  _Ball({
    required Shape shape,
    required this.velocity,
    required super.position,
  }) {
    add(
      ColliderNode(
          shape: shape,
          anchor: .center,
          layer: _BALL_LAYER,
          mask: _WALL_LAYER | _BALL_LAYER,
        )
        ..onCollisionStart((other) {
          switch (other.parent) {
            case _Ball():
              balls += 1;

            case _Wall(:final axis):
              switch (axis) {
                case .x:
                  velocity.x *= -1;

                case .y:
                  velocity.y *= -1;
              }
          }
        })
        ..onCollisionEnd((other) {
          switch (other.parent) {
            case _Ball():
              balls -= 1;
          }
        }),
    );
  }

  @override
  void tick(double dt) {
    position.addScaled(velocity, dt);
  }
}

Future<void> main() async {
  await runBenchmark(CollisionsBenchmark());
}
