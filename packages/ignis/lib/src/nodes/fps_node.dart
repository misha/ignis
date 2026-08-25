// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';

class FpsNode extends Node {
  /// The window size to use for FPS calculations. Defaults to 60.
  final int windowSize;

  /// The current frames per second (FPS).
  double fps = 0;

  /// Emits the latest rounded [fps] whenever it changes.
  final onFpsChange = Signal1<int>();

  final List<double> _window = [];
  double _sum = 0;
  int _last = 0;

  FpsNode({
    int? windowSize,
    super.enabled,
    super.priority,
    super.children,
  }) : assert(windowSize == null || windowSize > 0),
       windowSize = windowSize ?? 60;

  @override
  void build() {
    super.build();
    tick((dt) {
      if (dt <= 0 || !dt.isFinite) return;
      _window.add(dt);
      _sum += dt;

      if (_window.length > windowSize) {
        _sum -= _window.first;
        _window.removeAt(0);
      }

      final fps = _window.length / _sum;
      this.fps = fps.isFinite ? fps : 0;
      final rounded = this.fps.round();

      if (rounded != _last) {
        _last = rounded;
        onFpsChange.emit(rounded);
      }
    });
  }
}
