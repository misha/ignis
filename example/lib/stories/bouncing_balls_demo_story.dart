import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ignis/ignis.dart';

import '../hooks.dart';

final _RNG = Random();

//
// Demo Parameters
//

const _BALL_SPEED = 200.0;
const _BALL_SPAWN_INTERVAL = 0.002;

//
// Visual Parameters
//

const _BALL_RADIUS = 2.0;
const _WALL_THICKNESS = 5.0;
const _BOX_SIZE = 500.0;
const _BOX_CENTER = _BOX_SIZE / 2;
const _BOX_SPAN = _BOX_SIZE + _WALL_THICKNESS * 2;

const _WALL_COLOR = Colors.white;
const _BALL_COLOR = Colors.green;
const _COLLIDING_BALL_COLOR = Colors.red;

//
// Collision Parameters
//

const _WALL_LAYER = 1 << 0;
const _BALL_LAYER = 1 << 1;

class BouncingBallsDemoStory extends HookWidget {
  const BouncingBallsDemoStory();

  @override
  Widget build(context) {
    final version$ = useState(0);
    final paused$ = useState(false);
    final debug$ = useState(false);
    final fps$ = useState(0);
    final balls$ = useState(0);

    final version = version$.value;
    final scene = useMemoized(() => _DemoNode().mount(), [version]);
    final node = scene.node;
    final paused = paused$.value;
    final debug = debug$.value;
    final fps = fps$.value;
    final balls = balls$.value;

    useSignal1(node.fps.onFpsChange, (value) => fps$.value = value);
    useSignal1(node.onBalls, (value) => balls$.value = value);

    return SizedBox(
      width: _BOX_SIZE,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return .ignored;
          }

          switch (event.logicalKey) {
            case .space:
              paused$.value = !paused;

            case .keyR:
              version$.value += 1;

            case .keyQ:
              debug$.value = !debug;

            default:
              return .ignored;
          }

          return .handled;
        },
        child: Column(
          spacing: 5,
          mainAxisAlignment: .center,
          children: [
            Row(
              mainAxisAlignment: .spaceBetween,
              children: [
                Text('$balls balls'),
                Text('$fps FPS'),
              ],
            ),
            AspectRatio(
              aspectRatio: 1,
              child: SceneWidget(
                scene,
                paused: paused,
                debug: debug,
              ),
            ),
            Text(
              'space=${paused ? 'resume' : 'pause'} | '
              'q=${debug ? 'debug off' : 'debug on'} | '
              'r=restart',
            ),
          ],
        ),
      ),
    );
  }
}

class _DemoNode extends Node {
  late FpsNode fps;
  late CollisionDetectionNode cd;
  late _BoxNode box;
  late TimerNode spawner;

  /// The number of balls in the demo.
  int balls = 0;

  /// Emitted with the new ball count whenever a ball spawns.
  final onBalls = Signal1<int>();

  @override
  void build() {
    super.build();

    addAll([
      fps = FpsNode(),
      cd = CollisionDetectionNode(
        children: [
          box = _BoxNode(),
        ],
      ),
      spawner = TimerNode(
        interval: _BALL_SPAWN_INTERVAL,
        repeat: true,
      ),
    ]);

    balls = 0;

    spawner.onTrigger(() {
      final angle = _RNG.nextDouble() * 2 * pi;
      final velocity = MVector2(cos(angle), sin(angle))..scale(_BALL_SPEED);

      box.add(
        _BallNode(
          position: .all(_BOX_CENTER),
          velocity: velocity,
        ),
      );

      balls += 1;
      onBalls.emit(balls);
    });
  }
}

enum _Axis {
  x,
  y,
}

class _BoxNode extends ShapeNode {
  _BoxNode()
    : super(
        shape: .square(_BOX_SIZE),
        paint: Paint()
          ..style = .stroke
          ..strokeWidth = _WALL_THICKNESS
          ..color = _WALL_COLOR,
      );

  @override
  void build() {
    super.build();

    addAll([
      _WallNode(
        axis: .y,
        shape: .rectangle(.new(_BOX_SPAN, _WALL_THICKNESS)),
        position: .new(_BOX_CENTER, 0),
      ),
      _WallNode(
        axis: .y,
        shape: .rectangle(.new(_BOX_SPAN, _WALL_THICKNESS)),
        position: .new(_BOX_CENTER, _BOX_SIZE),
      ),
      _WallNode(
        axis: .x,
        shape: .rectangle(.new(_WALL_THICKNESS, _BOX_SPAN)),
        position: .new(0, _BOX_CENTER),
      ),
      _WallNode(
        axis: .x,
        shape: .rectangle(.new(_WALL_THICKNESS, _BOX_SPAN)),
        position: .new(_BOX_SIZE, _BOX_CENTER),
      ),
    ]);
  }
}

class _WallNode extends ColliderNode {
  final _Axis axis;

  _WallNode({
    required this.axis,
    required super.shape,
    required super.position,
  }) : super(
         anchor: .center,
         layer: _WALL_LAYER,
         priority: 1,
       );
}

class _BallNode extends ShapeNode {
  final MVector2 velocity;
  int collisions = 0;

  _BallNode({
    required this.velocity,
    super.position,
  }) : super(
         shape: .circle(_BALL_RADIUS),
         anchor: .center,
         paint: Paint()..color = _BALL_COLOR,
       );

  @override
  void build() {
    super.build();

    final collider = add(
      ColliderNode(
        shape: shape,
        anchor: anchor,
        layer: _BALL_LAYER,
        mask: _WALL_LAYER | _BALL_LAYER,
      ),
    );

    collider
      ..onCollisionStart((other) {
        switch (other) {
          case _WallNode(:final axis):
            switch (axis) {
              case .x:
                velocity.x *= -1;

              case .y:
                velocity.y *= -1;
            }

          case ColliderNode(parent: _BallNode()):
            collisions += 1;
            paint.color = _COLLIDING_BALL_COLOR;
        }
      })
      ..onCollisionEnd((other) {
        switch (other) {
          case ColliderNode(parent: _BallNode()):
            collisions -= 1;
            if (collisions <= 0) paint.color = _BALL_COLOR;
        }
      });

    onUpdate((dt) {
      position.addScaled(velocity, dt);
    });
  }
}
