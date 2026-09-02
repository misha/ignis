import 'dart:math';

import 'package:docs/rng.dart';
import 'package:flutter/material.dart';
import 'package:ignis/ignis.dart';

import '../colors.dart';
import '../demo_scene.dart';

const _IDLE_COLOR = GREEN;
const _HIT_COLOR = RED;

const _BLOCK = 20.0;
const _PROBE = 8.0;
const _GAP = 5.0;
const _PAD = 4.0;

const BLUE_LAYER = 1 << 0;
const ORANGE_LAYER = 1 << 1;

const _INITIAL_SPAWN_COUNT = 10;
const _SPAWN_INTERVAL = 0.01;
const _RADIUS = 2.5;
const _SPEED = 40.0;

final _LIMIT = DEMO_SIZE.x - _RADIUS;
final _CENTER = DEMO_SIZE / 2;

final Map<String, Widget Function()> collisionDemos = {
  'collision-pair': () => DemoScene(builder: _PairNode.new),
  'collision-active': () => DemoScene(builder: _ActiveNode.new),
  'collision-spin': () => DemoScene(builder: _SpinNode.new),
  'collision-layer': () => DemoScene(builder: _LayerNode.new),
  'collision-balls': () => DemoScene(builder: _ArenaNode.new),
};

PaletteEntry _stroke() {
  return PaletteEntry(
    'outline',
    Paint()
      ..style = .stroke
      ..strokeWidth = 0
      ..color = Colors.black,
    priority: 1,
  );
}

ShapeNode _still(
  Shape shape, {
  Vector2? position,
  Color color = BLUE,
}) {
  final node = ShapeNode(
    shape: shape,
    anchor: .center,
    position: position,
    paint: Paint()..color = color,
  );

  return node..palette.add(_stroke());
}

ShapeNode _mover(
  Shape shape, {
  double seconds = 1.6,
}) {
  final node = ShapeNode(
    shape: shape,
    anchor: .center,
    position: .new(shape.width / 2, _CENTER.y),
    paint: Paint()..color = _IDLE_COLOR,
  );

  return node
    ..palette.add(_stroke())
    ..add(
      MoveEffect.by(
        offset: .new(DEMO_SIZE.x - shape.width, 0),
        controller: .infinite(.roundtrip(.duration(seconds))),
      ),
    );
}

BoxNode _caption(DemoLog log) {
  return BoxNode(
    padding: .all(_PAD),
    alignment: .bottomCenter,
    children: [log],
  );
}

void _colorOnContact(ShapeNode node, ColliderNode collider) {
  collider
    ..onCollisionStart((_) {
      node.paint.color = _HIT_COLOR;
    })
    ..onCollisionEnd((_) {
      if (!collider.isColliding) node.paint.color = _IDLE_COLOR;
    });
}

/// A circle sliding through a square, reporting each edge as it crosses.
class _PairNode extends CollisionArenaNode {
  @override
  void build() {
    super.build();
    final log = DemoLog();

    final wall = add(_still(.square(_BLOCK), position: _CENTER));
    wall.add(ColliderNode());

    final mover = add(_mover(.circle(_PROBE))..paint.blendMode = .plus);

    // demo on collision-pair
    final collider = mover.add(ColliderNode());

    collider
      ..onCollisionStart((_) => log('colliding', RED))
      ..onCollisionEnd((_) => log('not colliding', GREEN));
    // demo off

    log('not colliding', GREEN);
    add(_caption(log));
  }
}

/// A circle crossing three squares, counting what it touches every tick.
class _ActiveNode extends CollisionArenaNode {
  @override
  void build() {
    super.build();
    final log = DemoLog();
    final blocks = [
      for (var i = 0; i < 3; i += 1) //
        _still(.square(_BLOCK)),
    ];

    for (final block in blocks) {
      block.add(ColliderNode());
    }

    add(
      BoxNode(
        alignment: .center,
        children: [
          RowNode(
            mainAxisSize: .min,
            spacing: _GAP,
            children: blocks,
          ),
        ],
      ),
    );

    final mover = add(
      _mover(.circle(_PROBE)) //
        ..paint.blendMode = .plus,
    );

    // demo on collision-active
    final collider = mover.add(ColliderNode());

    tick((_) {
      log(switch (collider.active.length) {
        0 => "can't touch this!",
        final n => 'touching $n',
      });
    });
    // demo off

    add(_caption(log));
  }
}

/// A long hitbox turning through a circle its bounding box never leaves.
class _SpinNode extends CollisionArenaNode {
  @override
  void build() {
    super.build();

    final circle = add(_still(.circle(16), position: _CENTER / 2));

    circle.add(ColliderNode());

    // demo on collision-spin
    final blade = add(
      ShapeNode(
        shape: .rectangle(.new(70, 10)),
        anchor: .center,
        position: _CENTER,
        paint: Paint()..color = _IDLE_COLOR,
      ),
    );

    final collider = blade.add(ColliderNode());

    blade.add(SpinEffect(speed: pi / 2));
    // demo off

    blade.palette.add(_stroke());
    _colorOnContact(blade, collider);
  }
}

/// A circle that reports over one of the two squares it crosses, not the other.
class _LayerNode extends CollisionArenaNode {
  @override
  void build() {
    super.build();
    final blue = _still(.square(_BLOCK));
    final orange = _still(.square(_BLOCK), color: ORANGE);

    add(
      BoxNode(
        alignment: .center,
        children: [
          RowNode(
            mainAxisSize: .min,
            spacing: _BLOCK + _GAP,
            children: [blue, orange],
          ),
        ],
      ),
    );

    final mover = add(_mover(.circle(_PROBE)));

    // demo on collision-layer
    blue.add(ColliderNode(layer: BLUE_LAYER));
    orange.add(ColliderNode(layer: ORANGE_LAYER));
    final collider = mover.add(ColliderNode(mask: ORANGE_LAYER));
    // demo off

    _colorOnContact(mover, collider);
  }
}

/// A stroked white caption pinned to one corner of the stage.
class _LabelNode extends BoxNode {
  final _fill = DemoLog();
  final _outline = TextNode(
    style: TextStyle(
      foreground: Paint()
        ..style = .stroke
        ..strokeWidth = 1.5
        ..color = const Color(0xFF000000),
    ),
  );

  _LabelNode({
    required Anchor alignment,
  }) : super(
         alignment: alignment,
         padding: .all(_PAD),
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
    _fill(text, BRIGHT);
  }
}

/// An arena that pours balls from the middle, and from wherever you hold.
class _ArenaNode extends CollisionArenaNode {
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
    final angle = rng.nextDouble() * 2 * pi;

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
         paint: Paint()..color = _IDLE_COLOR,
       );

  @override
  void build() {
    super.build();
    add(VelocityEffect(velocity: velocity));

    // demo on collision-balls
    final collider = add(ColliderNode());

    collider
      ..onCollisionStart((_) {
        paint.color = _HIT_COLOR;
      })
      ..onCollisionEnd((_) {
        if (!collider.isColliding) {
          paint.color = _IDLE_COLOR;
        }
      });
    // demo off

    tick((_) {
      if (position.x < _RADIUS || position.x > _LIMIT) velocity.x *= -1;
      if (position.y < _RADIUS || position.y > _LIMIT) velocity.y *= -1;
      position.clampTo(_RADIUS, _LIMIT);
    });
  }
}
