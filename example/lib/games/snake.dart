import 'dart:math';

import 'package:ignis/ignis.dart';

//
// Data
//

class Tile {
  final int x;
  final int y;

  const Tile(this.x, this.y);

  Tile operator +(Tile other) => Tile(x + other.x, y + other.y);

  Vector2 get vector => .cast(x, y);

  @override
  bool operator ==(Object other) =>
      other is Tile && //
      x == other.x &&
      y == other.y;

  @override
  int get hashCode => Object.hash(x, y);
}

enum Direction {
  up(0, -1),
  down(0, 1),
  left(-1, 0),
  right(1, 0);

  final int dx;
  final int dy;

  const Direction(this.dx, this.dy);

  Tile get delta => Tile(dx, dy);

  Direction get opposite => switch (this) {
    .up => .down,
    .down => .up,
    .left => .right,
    .right => .left,
  };
}

//
// Entities
//

sealed class Entity {
  const Entity();
}

class Food extends Entity {
  final Tile tile;

  const Food({
    required this.tile,
  });
}

class Snake extends Entity {
  final int index;

  Tile _tile;
  Tile get tile => _tile;

  Snake({
    required this.index,
    required this._tile,
  });
}

//
// Events
//

sealed class SnakeGameEvent {
  const SnakeGameEvent();
}

class SnakeGrewEvent extends SnakeGameEvent {
  final Snake segment;

  const SnakeGrewEvent(this.segment);
}

class SnakeMovedEvent extends SnakeGameEvent {
  final Snake segment;
  final Tile from;

  const SnakeMovedEvent(this.segment, this.from);
}

class FoodSpawnedEvent extends SnakeGameEvent {
  final Food food;

  const FoodSpawnedEvent(this.food);
}

class FoodEatenEvent extends SnakeGameEvent {
  final Food food;

  const FoodEatenEvent(this.food);
}

class GameOverEvent extends SnakeGameEvent {
  const GameOverEvent();
}

//
// Logic
//

class SnakeGame {
  final int size;
  final double snakeSpeed;
  final double foodSpawnInterval;

  final List<Snake> _segments = [];
  final Set<Food> _foods = {};

  Iterable<Snake> get segments => _segments;
  Iterable<Food> get foods => _foods;
  final onEvent = Signal1<SnakeGameEvent>();

  Direction _direction = .right;
  final List<Direction> _pendingDirections = [];
  late Tile _lastTail;
  double _moveElapsed = 0;
  double _foodElapsed = 0;
  bool _gameOver = false;
  int _nextSegment = 0;
  final Random _rng;

  int get score => segments.length * 10 - 30;
  bool get isGameOver => _gameOver;

  SnakeGame({
    required this.size,
    required this.snakeSpeed,
    required this.foodSpawnInterval,
    int? seed,
  }) : _rng = Random(seed) {
    final start = size ~/ 2;

    _segments.addAll([
      Snake(index: _nextSegment++, tile: Tile(start, start)),
      Snake(index: _nextSegment++, tile: Tile(start - 1, start)),
      Snake(index: _nextSegment++, tile: Tile(start - 2, start)),
    ]);

    _lastTail = _segments.last.tile;
  }

  void turn(Direction direction) {
    // Store up to 2 directions, validating against the last one. This way a
    // burst of individually valid turns cannot collapse into a reversal just
    // because they all arrive before the next step.
    if (_pendingDirections.length >= 2) return;
    final current = _pendingDirections.lastOrNull ?? _direction;
    if (direction == current.opposite) return;
    _pendingDirections.add(direction);
  }

  void eat(Food food) {
    _foods.remove(food);
    onEvent.emit(FoodEatenEvent(food));
    final snake = Snake(index: _nextSegment++, tile: _lastTail);
    _segments.add(snake);
    onEvent.emit(SnakeGrewEvent(snake));
  }

  void collide() {
    _gameOver = true;
    onEvent.emit(const GameOverEvent());
  }

  void update(double dt) {
    if (_gameOver) return;
    _foodElapsed += dt;

    while (_foodElapsed >= foodSpawnInterval) {
      _foodElapsed -= foodSpawnInterval;
      _spawnFood();
    }

    final moveInterval = 1 / snakeSpeed;
    _moveElapsed += dt;

    while (_moveElapsed >= moveInterval) {
      _moveElapsed -= moveInterval;
      _step();
      if (_gameOver) return;
    }
  }

  void _spawnFood() {
    final occupied = {
      for (final segment in _segments) //
        segment.tile,
      for (final food in _foods) //
        food.tile,
    };

    final free = [
      for (var x = 0; x < size; x += 1)
        for (var y = 0; y < size; y += 1)
          if (!occupied.contains(Tile(x, y))) //
            Tile(x, y),
    ];

    if (free.isEmpty) return;
    final food = Food(tile: free[_rng.nextInt(free.length)]);
    _foods.add(food);
    onEvent.emit(FoodSpawnedEvent(food));
  }

  void _step() {
    if (_pendingDirections.isNotEmpty) {
      _direction = _pendingDirections.removeAt(0);
    }

    final head = _segments.first;
    final newHead = head.tile + _direction.delta;
    _lastTail = _segments.last.tile;

    final previousTiles = [
      for (final segment in _segments) //
        segment.tile,
    ];

    for (var i = _segments.length - 1; i > 0; i -= 1) {
      _segments[i]._tile = _segments[i - 1].tile;
    }

    head._tile = newHead;

    for (var i = 0; i < _segments.length; i += 1) {
      onEvent.emit(SnakeMovedEvent(_segments[i], previousTiles[i]));
    }
  }
}
