import 'package:ignis/src/math.dart';

/// Something with a position.
abstract interface class PositionOwner {
  Vector2 get position;

  /// Boxes a position.
  static PositionOwner box([Vector2? position]) => _PositionBox(position ?? .zero());
}

final class _PositionBox implements PositionOwner {
  @override
  final Vector2 position;

  _PositionBox(this.position);
}
