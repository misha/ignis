import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:ignis/ignis.dart';

import '../demo_scene.dart';

const _IDLE = Color(0xFF7FA6C4);
const _HIT = Color(0xFFC78F30);
const _COUNT = 100;
const _RADIUS = 3.0;
const _SPEED = 40.0;
const _SEED = 12345;

final _LIMIT = DEMO_SIZE.x - _RADIUS;

/// The demos on the Collisions page, by the name their `<Demo/>` slot carries.
final Map<String, Widget Function()> collisionDemos = {
  'collision-balls': () => DemoScene(builder: _BallsNode.new),
};

/// An arena packed with balls, each one coloring itself while it touches another.
class _BallsNode extends CollisionDetectionNode {
  @override
  void build() {
    super.build();
    final random = Random(_SEED);

    for (var i = 0; i < _COUNT; i += 1) {
      add(
        _BallNode(
          position: .new(
            _RADIUS + random.nextDouble() * (_LIMIT - _RADIUS),
            _RADIUS + random.nextDouble() * (_LIMIT - _RADIUS),
          ),
          velocity: .new(
            (random.nextDouble() - 0.5) * _SPEED,
            (random.nextDouble() - 0.5) * _SPEED,
          ),
        ),
      );
    }
  }
}

/// One ball, drifting until it hits a wall and turning while it overlaps.
class _BallNode extends ShapeNode {
  final MVector2 velocity;

  _BallNode({
    required this.velocity,
    required super.position,
  }) : super(
         shape: .circle(_RADIUS),
         anchor: .center,
         paint: Paint()..color = _IDLE,
       );

  @override
  void build() {
    super.build();
    add(VelocityEffect(velocity: velocity));

    // demo on collision-balls
    final collider = add(
      ColliderNode(
        shape: shape,
        anchor: anchor,
      ),
    );

    collider
      ..onCollisionStart((_) {
        paint.color = _HIT;
      })
      ..onCollisionEnd((_) {
        if (!collider.isColliding) paint.color = _IDLE;
      });
    // demo off

    tick((_) {
      if (position.x < _RADIUS || position.x > _LIMIT) velocity.x *= -1;
      if (position.y < _RADIUS || position.y > _LIMIT) velocity.y *= -1;
      position.clampTo(_RADIUS, _LIMIT);
    });
  }
}
