import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:ignis/ignis.dart';

import '../demo_scene.dart';

const _IDLE = Color(0xFF8FB07A);
const _HIT = Color(0xFFC4756A);
const _INITIAL_SPAWN_COUNT = 10;
const _SPAWN_INTERVAL = 0.05;
const _RADIUS = 3.0;
const _SPEED = 40.0;
const _SEED = 12345;

final _LIMIT = DEMO_SIZE.x - _RADIUS;
final _CENTER = DEMO_SIZE / 2;

/// The demos on the Collisions page, by the name their `<Demo/>` slot carries.
final Map<String, Widget Function()> collisionDemos = {
  'collision-balls': () => DemoScene(builder: _ArenaNode.new),
};

/// A stroked white caption pinned to one corner of the stage.
class _LabelNode extends BoxNode {
  final _fill = DemoLog();
  final _outline = TextNode(
    style: DEMO_TEXT_STYLE.copyWith(
      foreground: Paint()
        ..style = .stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF000000),
    ),
  );

  _LabelNode({required Anchor alignment})
    : super(
        alignment: alignment,
        padding: .all(4),
        priority: 1,
      );

  @override
  void build() {
    super.build();
    add(_outline);
    add(_fill..priority = 1);
  }

  void call(String text) {
    _outline.text = text;
    _fill(text, .white);
  }
}

/// An arena that pours balls from the middle, and from wherever you hold.
class _ArenaNode extends CollisionDetectionNode {
  final _random = Random(_SEED);
  final MVector2 _source = .zero();

  final _count = _LabelNode(alignment: .topRight);
  final _fps = _LabelNode(alignment: .topLeft);

  int _balls = 0;

  @override
  void build() {
    super.build();

    add(_count);
    add(_fps);

    final frames = add(FpsNode());

    frames.onFpsChange((value) {
      _fps('$value fps');
    });

    _count('$_balls balls');

    final pour = add(
      TimerNode(
        interval: _SPAWN_INTERVAL,
        count: _INITIAL_SPAWN_COUNT,
        cleanup: true,
      ),
    );

    pour.onTrigger(() {
      _spawn(_CENTER);
    });

    final spawner = add(
      TimerNode(
        interval: _SPAWN_INTERVAL,
        repeat: true,
        enabled: false,
      ),
    );

    spawner.onTrigger(() {
      _spawn(_source);
    });

    final drags = add(
      DragInput(
        shape: .rectangle(DEMO_SIZE),
        endOnCancel: true,
      ),
    );

    drags
      ..onDragStart((event) {
        _source.setFrom(event.scene);
        spawner.enable();
      })
      ..onDragUpdate((event) {
        _source.setFrom(event.scene);
      })
      ..onDragEnd((_) {
        spawner.disable();
      });
  }

  void _spawn(Vector2 at) {
    _balls += 1;
    _count('$_balls balls');
    final angle = _random.nextDouble() * 2 * pi;

    add(
      _BallNode(
        position: .copy(at),
        velocity: .new(cos(angle) * _SPEED, sin(angle) * _SPEED),
      ),
    );
  }
}

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
