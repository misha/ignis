import 'package:ignis/src/node.dart';

class FpsNode extends Node {
  /// The window size to use for FPS calculations. Defaults to 60.
  final int windowSize;

  /// The current frames per second (FPS).
  double fps = 0;

  final List<double> _window = [];
  double _sum = 0;

  FpsNode({
    int? windowSize,
    super.priority,
    super.children,
  }) : assert(windowSize == null || windowSize > 0),
       windowSize = windowSize ?? 60;

  @override
  void tick(double dt) {
    if (dt <= 0 || !dt.isFinite) return;
    _window.add(dt);
    _sum += dt;

    if (_window.length > windowSize) {
      _sum -= _window.first;
      _window.removeAt(0);
    }

    final fps = _window.length / _sum;
    this.fps = fps.isFinite ? fps : 0;
  }
}
