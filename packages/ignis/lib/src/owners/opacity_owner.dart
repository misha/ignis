/// Something with an opacity.
abstract interface class OpacityOwner {
  double get opacity;
  set opacity(double value);

  /// Boxes an opacity.
  static OpacityOwner box([double? opacity]) => _OpacityBox(opacity ?? 1);
}

final class _OpacityBox implements OpacityOwner {
  @override
  double opacity;

  _OpacityBox(this.opacity);
}
