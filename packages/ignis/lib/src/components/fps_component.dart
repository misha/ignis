// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
import 'package:ignis/src/message.dart';

class FpsComponent extends Component {
  /// The window size to use for FPS calculations. Defaults to 60.
  final int windowSize;

  /// The current frames per second (FPS).
  double fps = 0;

  final List<double> _window = [];
  double _sum = 0;
  int _last = 0;

  FpsComponent({
    int? windowSize,
    super.id,
    super.enabled,
    super.priority,
  }) : assert(windowSize == null || windowSize > 0),
       windowSize = windowSize ?? 60;

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Update(:final dt):
        if (dt <= 0 || !dt.isFinite) break;
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
          entity.post(FpsChange(this, rounded));
        }
    }
  }
}

/// Emitted with the latest rounded [FpsComponent.fps] whenever it changes.
final class FpsChange extends Message {
  final FpsComponent component;

  final int fps;

  const FpsChange(this.component, this.fps);
}
