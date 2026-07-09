import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ignis/ignis.dart';

class BouncingBalls extends HookWidget {
  const BouncingBalls();

  @override
  Widget build(context) {
    final version = useState(0);
    final paused = useState(true);
    final demo = useMemoized(() => _DemoNode(), [version.value]);
    final scene = useMemoized(() => demo.mount(), [demo]);

    return SizedBox.expand(
      child: Stack(
        children: [
          Positioned.fill(
            child: SceneWidget(
              scene,
              paused: paused.value,
            ),
          ),
          Positioned(
            right: 16,
            bottom: 16,
            child: Column(
              mainAxisSize: .min,
              spacing: 8,
              children: [
                ElevatedButton.icon(
                  onPressed: () => paused.value = !paused.value,
                  icon: Icon(paused.value ? Icons.play_arrow : Icons.stop),
                  label: Text(paused.value ? 'Start' : 'Stop'),
                ),
                ElevatedButton.icon(
                  onPressed: () => version.value += 1,
                  icon: const Icon(Icons.refresh),
                  label: Text('Reset'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

final rng = Random();

const _BALL_RADIUS = 2.0;
const _BALL_SPEED = 200.0;
const _BALL_SPAWN_INTERVAL = 0.002;
const _WALL_THICKNESS = 20.0;
const _LABEL_MARGIN = 8.0;
const _LABEL_HEIGHT = 14.0;
const _BOX_SIZE = 500.0;
const _BOX_LEFT = -_BOX_SIZE / 2 - _WALL_THICKNESS;
const _BOX_TOP = -_BOX_SIZE / 2 - _LABEL_MARGIN - _WALL_THICKNESS;
const _BOX_SPAN = _BOX_SIZE + _WALL_THICKNESS * 2;

const _WALL_LAYER = 1 << 0;
const _BALL_LAYER = 1 << 1;

class _DemoNode extends TransformNode {
  final fps = FpsNode();
  final cd = CollisionDetectionNode();
  final box = _BoxNode();
  final spawner = TimerNode(
    interval: _BALL_SPAWN_INTERVAL,
    repeat: true,
  );

  final fpsLabel = TextNode(
    position: .new(_BOX_LEFT, _BOX_TOP - _LABEL_HEIGHT),
    anchor: .bottomLeft(),
  );

  final ballsLabel = TextNode(
    position: .new(_BOX_LEFT, _BOX_TOP),
    anchor: .bottomLeft(),
  );

  int balls = 0;

  _DemoNode() {
    spawner.onTrigger(() {
      final angle = rng.nextDouble() * 2 * pi;
      final velocity = Vector2(cos(angle), sin(angle)) * _BALL_SPEED;
      cd.add(_BallNode(velocity: velocity));
      balls += 1;
    });

    cd.add(box);
    addAll([fpsLabel, ballsLabel, fps, spawner, cd]);
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
          ..color = Colors.white,
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
         paint: Paint()..color = Colors.green,
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
              paint.color = Colors.red;
          }
        })
        ..onCollisionEnd((other) {
          switch (other) {
            case ColliderNode(parent: _BallNode()):
              collisions -= 1;
              if (collisions <= 0) paint.color = Colors.green;
          }
        }),
    );
  }

  @override
  void tick(double dt) {
    position.mutate().addScaled(velocity, dt);
  }
}
