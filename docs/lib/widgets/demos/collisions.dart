import 'dart:math';

import 'package:flutter/widgets.dart';
import 'package:ignis/ignis.dart';

import '../demo_scene.dart';

const _IDLE = Color(0xFF8FB07A);
const _HIT = Color(0xFFC4756A);
const _INITIAL = 50;
const _INTERVAL = 0.02;
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
  final MVector2 _source = .copy(_CENTER);

  final _count = _LabelNode(alignment: .topRight);
  final _fps = _LabelNode(alignment: .topLeft);

  int _pending = _INITIAL;
  int _balls = 0;
  bool _held = false;

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

    final taps = add(
      TapInput(
        shape: .rectangle(DEMO_SIZE),
        behavior: .translucent,
      ),
    );

    final drags = add(
      DragInput(
        shape: .rectangle(DEMO_SIZE),
        behavior: .translucent,
      ),
    );

    taps
      ..onTapDown((event) {
        _held = true;
        _source.setFrom(event.scene);
      })
      ..onTapUp((_) {
        _held = false;
      })
      ..onTapCancel(() {
        _held = drags.isDragging;
      });

    drags
      ..onDragStart((event) {
        _held = true;
        _source.setFrom(event.scene);
      })
      ..onDragUpdate((event) {
        _source.setFrom(event.scene);
      })
      ..onDragEnd((_) {
        _held = false;
      })
      ..onDragCancel(() {
        _held = false;
      });

    final spawns = add(
      TimerNode(
        interval: _INTERVAL,
        repeat: true,
      ),
    );

    spawns.onTrigger(() {
      if (_pending > 0) {
        _pending -= 1;
        _spawn(_CENTER);
        return;
      }

      if (_held) _spawn(_source);
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
