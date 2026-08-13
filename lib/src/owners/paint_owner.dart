import 'dart:ui';

/// Something with a paint.
abstract interface class PaintOwner {
  Paint get paint;

  /// Boxes a paint.
  static PaintOwner box([Paint? paint]) => _PaintBox(paint ?? Paint());
}

final class _PaintBox implements PaintOwner {
  @override
  final Paint paint;

  _PaintBox(this.paint);
}
