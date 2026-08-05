import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ignis/ignis.dart';

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
const _BOX_LEFT = -_BOX_SIZE / 2 - _WALL_THICKNESS;
const _BOX_RIGHT = -_BOX_LEFT;
const _BOX_TOP = -_BOX_SIZE / 2 - _WALL_THICKNESS;
const _BOX_SPAN = _BOX_SIZE + _WALL_THICKNESS * 2;

const _TEXT_COLOR = Colors.white;
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

    final version = version$.value;
    final node = useMemoized(() => _DemoNode(), [version]);
    final paused = paused$.value;
    final debug = debug$.value;

    return Focus(
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
        spacing: 10,
        mainAxisAlignment: .center,
        children: [
          SizedBox.square(
            dimension: 500,
            child: SceneWidget(
              node.mount(),
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
    );
  }
}

class _DemoNode extends TransformNode {
  late final FpsNode fps;
  late final TextNode ballsLabel;
  late final TextNode fpsLabel;
  late final CollisionDetectionNode cd;
  late final TimerNode spawner;

  int balls = 0;

  _DemoNode() {
    addAll([
      fps = FpsNode(),
      ballsLabel = TextNode(
        position: .new(_BOX_LEFT + 2, _BOX_TOP),
        anchor: .bottomLeft(),
        style: const TextStyle(color: _TEXT_COLOR),
        priority: 1,
      ),
      fpsLabel = TextNode(
        position: .new(_BOX_RIGHT - 2, _BOX_TOP),
        anchor: .bottomRight(),
        style: const TextStyle(color: _TEXT_COLOR),
        priority: 1,
      ),
      cd = CollisionDetectionNode(
        children: [
          _BoxNode(),
        ],
      ),
      spawner = TimerNode(
        interval: _BALL_SPAWN_INTERVAL,
        repeat: true,
      ),
    ]);

    spawner.onTrigger(() {
      final angle = _RNG.nextDouble() * 2 * pi;
      final velocity = Vector2(cos(angle), sin(angle)) * _BALL_SPEED;
      cd.add(_BallNode(velocity: velocity));
      balls += 1;
    });
  }

  @override
  void tick(double dt) {
    fpsLabel.text = '${fps.fps.round()} FPS';
    ballsLabel.text = '$balls balls';
  }
}

enum _Axis {
  x,
  y,
}

class _BoxNode extends ShapeNode {
  _BoxNode()
    : super(
        shape: .rectangle,
        size: .all(_BOX_SIZE),
        anchor: .center(),
        paint: Paint()
          ..style = .stroke
          ..strokeWidth = _WALL_THICKNESS
          ..color = _WALL_COLOR,
      ) {
    addAll([
      _WallNode(
        axis: .y,
        shape: .rectangle,
        size: .new(_BOX_SPAN, _WALL_THICKNESS),
        position: .new(0, -_BOX_SIZE / 2),
      ),
      _WallNode(
        axis: .y,
        shape: .rectangle,
        size: .new(_BOX_SPAN, _WALL_THICKNESS),
        position: .new(0, _BOX_SIZE / 2),
      ),
      _WallNode(
        axis: .x,
        shape: .rectangle,
        size: .new(_WALL_THICKNESS, _BOX_SPAN),
        position: .new(-_BOX_SIZE / 2, 0),
      ),
      _WallNode(
        axis: .x,
        shape: .rectangle,
        size: .new(_WALL_THICKNESS, _BOX_SPAN),
        position: .new(_BOX_SIZE / 2, 0),
      ),
    ]);
  }
}

class _WallNode extends ColliderNode {
  final _Axis axis;

  _WallNode({
    required this.axis,
    required super.shape,
    required super.size,
    required super.position,
  }) : super(
         anchor: .center(),
         layer: _WALL_LAYER,
         priority: 1,
       );
}

class _BallNode extends ShapeNode {
  final Vector2 velocity;
  int collisions = 0;

  _BallNode({
    required this.velocity,
  }) : super(
         shape: .circle,
         size: .all(_BALL_RADIUS * 2),
         anchor: .center(),
         paint: Paint()..color = _BALL_COLOR,
       ) {
    add(
      ColliderNode(
          shape: shape,
          size: size,
          anchor: anchor,
          layer: _BALL_LAYER,
          mask: _WALL_LAYER | _BALL_LAYER,
        )
        ..onCollisionStart((other) {
          switch (other) {
            case _WallNode(:final axis):
              switch (axis) {
                case .x:
                  velocity.mutate().x *= -1;

                case .y:
                  velocity.mutate().y *= -1;
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
        }),
    );
  }

  @override
  void tick(double dt) {
    position.mutate().addScaled(velocity, dt);
  }
}
