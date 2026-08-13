import 'package:ignis/src/math.dart';

/// Something with a scale.
abstract interface class ScaleOwner {
  Vector2 get scale;

  /// Boxes a scale.
  static ScaleOwner box([Vector2? scale]) => _ScaleBox(scale ?? .all(1));
}

final class _ScaleBox implements ScaleOwner {
  @override
  final Vector2 scale;

  _ScaleBox(this.scale);
}
