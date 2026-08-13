/// Something with a speed.
abstract interface class SpeedOwner {
  double get speed;
  set speed(double value);

  /// Boxes a speed.
  static SpeedOwner box([double? speed]) => _SpeedBox(speed ?? 0);
}

final class _SpeedBox implements SpeedOwner {
  @override
  double speed;

  _SpeedBox(this.speed);
}
