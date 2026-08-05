import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ignis/ignis.dart';

import '../games/snake.dart';

//
// Game Parameters
//

const _GRID_SIZE = 12;
const _SNAKE_SPEED = 4.0;
const _FOOD_SPAWN_INTERVAL = 2.0;

SnakeGame _makeGame() {
  return SnakeGame(
    size: _GRID_SIZE,
    snakeSpeed: _SNAKE_SPEED,
    foodSpawnInterval: _FOOD_SPAWN_INTERVAL,
  );
}

//
// Visual Parameters
//

const _TILE_SIZE = 32.0;
const _BOARD_SIZE = _GRID_SIZE * _TILE_SIZE;
const _SNAKE_SIZE = _TILE_SIZE * 0.8; // A little smaller.
const _FOOD_SIZE = _TILE_SIZE * 0.5; // A lot smaller.
const _WALL_THICKNESS = 1.0;

const _SNAKE_COLOR = Colors.white;
const _SNAKE_HEAD_COLOR = Colors.orange;
const _FOOD_COLOR = Colors.red;
const _WALL_COLOR = Colors.white;

//
// Collision Parameters
//

const _SNAKE_LAYER = 1 << 0;
const _FOOD_LAYER = 1 << 1;
const _WALL_LAYER = 1 << 2;

//
// Story
//

class SnakeGameStory extends HookWidget {
  const SnakeGameStory();

  @override
  Widget build(context) {
    final game$ = useState(_makeGame());
    final paused$ = useState(false);
    final debug$ = useState(false);

    final game = game$.value;
    final node = useMemoized(() => _GameNode(game), [game]);
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
            game$.value = _makeGame();

          case .keyQ:
            debug$.value = !debug;

          case .arrowUp || .keyW:
            game.turn(.up);

          case .arrowDown || .keyS:
            game.turn(.down);

          case .arrowLeft || .keyA:
            game.turn(.left);

          case .arrowRight || .keyD:
            game.turn(.right);

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
            'wasd/arrows to move | '
            'space=${paused ? 'resume' : 'pause'} | '
            'q=${debug ? 'debug off' : 'debug on'} | '
            'r=restart',
          ),
        ],
      ),
    );
  }
}

class _GameNode extends TransformNode {
  final SnakeGame game;

  late final TransformNode board;
  late final TextNode scoreText;
  late final TextNode fpsText;
  late final FpsNode fps;

  _GameNode(this.game) {
    addAll([
      TransformNode(
        position: .all(-_BOARD_SIZE / 2),
        children: [
          CollisionDetectionNode(
            children: [
              board = TransformNode(
                children: [
                  // Set up horizontal walls.
                  for (final x in [0.0, _BOARD_SIZE]) //
                    _WallNode(
                      shape: .rectangle,
                      size: .new(_WALL_THICKNESS, _BOARD_SIZE),
                      position: .new(x, _BOARD_SIZE / 2),
                    ),

                  // Set up vertical walls.
                  for (final y in [0.0, _BOARD_SIZE]) //
                    _WallNode(
                      shape: .rectangle,
                      size: .new(_BOARD_SIZE, _WALL_THICKNESS),
                      position: .new(_BOARD_SIZE / 2, y),
                    ),

                  // Add the initial snake segments.
                  for (final segment in game.segments) //
                    _SegmentNode(game, segment),
                ],
              ),
            ],
          ),
          scoreText = TextNode(
            position: .new(0, -4),
            anchor: .bottomLeft(),
          ),
          fpsText = TextNode(
            position: .new(_BOARD_SIZE, -4),
            anchor: .bottomRight(),
          ),
        ],
      ),
      fps = FpsNode(),
    ]);

    game.onEvent((event) {
      switch (event) {
        case FoodSpawnedEvent(:final food):
          board.add(_FoodNode(game, food));

        case SnakeGrewEvent(:final segment):
          board.add(_SegmentNode(game, segment));

        default:
      }
    });
  }

  @override
  void tick(double dt) {
    game.update(dt);
    final score = game.segments.length * 10 - 30;

    if (game.isGameOver) {
      scoreText.text = 'Game over! Your score was $score.';
    } else {
      scoreText.text = 'Score: $score';
    }

    fpsText.text = '${fps.fps.round()} FPS';
  }
}

class _WallNode extends ShapeNode {
  _WallNode({
    required super.shape,
    required super.size,
    required super.position,
  }) : super(
         anchor: .center(),
         paint: Paint()..color = _WALL_COLOR,
       ) {
    add(
      ColliderNode(
        shape: shape,
        size: size,
        anchor: anchor,
        layer: _WALL_LAYER,
        mask: 0,
      ),
    );
  }
}

class _SegmentNode extends ShapeNode {
  final SnakeGame game;
  final int index;

  bool get isHead => index == 0;

  _SegmentNode(this.game, Snake segment)
    : index = segment.index,
      super(
        shape: .circle,
        size: .all(_SNAKE_SIZE),
        anchor: .center(),
        position: segment.tile.position,
      ) {
    paint.color = isHead ? _SNAKE_HEAD_COLOR : _SNAKE_COLOR;

    add(
      ColliderNode(
        shape: shape,
        size: size,
        anchor: .center(),
        layer: _SNAKE_LAYER,
        mask: _SNAKE_LAYER | _FOOD_LAYER | _WALL_LAYER,
      )..onCollisionStart((other) {
        switch (other.parent) {
          case _SegmentNode(:final index):
            // Don't collide adjacent nodes, as they can touch while turning.
            if ((this.index - index).abs() <= 1) break;
            game.collide();

          case _FoodNode(:final food):
            game.eat(food);

          case _WallNode():
            game.collide();
        }
      }),
    );

    game.onEvent((event) {
      switch (event) {
        case SnakeMovedEvent(:final segment, :final from):
          if (segment.index == index) {
            add(
              MoveEffect.by(
                position: position,
                offset: segment.tile.position - from.position,
                controller: EffectController(
                  duration: 1 / _SNAKE_SPEED,
                  cleanup: true,
                ),
              ),
            );
          }

        case GameOverEvent():
          // Stop moving when the game ends.
          for (final child in children) {
            if (child is MoveEffect) {
              child.detach();
            }
          }

        default:
      }
    });
  }
}

class _FoodNode extends ShapeNode {
  final SnakeGame game;
  final Food food;

  _FoodNode(this.game, this.food)
    : super(
        shape: .circle,
        size: .all(_FOOD_SIZE),
        anchor: .center(),
        position: food.tile.position,
        paint: Paint()..color = _FOOD_COLOR,
      ) {
    add(
      ColliderNode(
        shape: shape,
        size: size,
        anchor: .center(),
        layer: _FOOD_LAYER,
        mask: 0,
      ),
    );

    game.onEvent((event) {
      switch (event) {
        case FoodEatenEvent(:final food):
          if (food == this.food) {
            detach();
          }

        default:
      }
    });
  }
}

extension on Tile {
  Vector2 get position => vector
    ..modify((tile) {
      tile
        ..addAll(0.5)
        ..scale(_TILE_SIZE);
    });
}
