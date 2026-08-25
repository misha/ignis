// SPDX-AI-Disclosure: none

/// Something with an angle.
abstract interface class AngleOwner {
  double get angle;
  set angle(double value);

  /// Boxes an angle.
  static AngleOwner box([double? angle]) => _AngleBox(angle ?? 0);
}

final class _AngleBox implements AngleOwner {
  @override
  double angle;

  _AngleBox(this.angle);
}
