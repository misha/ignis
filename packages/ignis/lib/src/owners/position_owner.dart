import 'package:ignis/src/math.dart';

/// Something with a position.
abstract interface class PositionOwner {
  MVector2 get position;

  /// Boxes a position.
  static PositionOwner box([MVector2? position]) => _PositionBox(position ?? .zero());
}

final class _PositionBox implements PositionOwner {
  @override
  final MVector2 position;

  _PositionBox(this.position);
}
