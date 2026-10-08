// SPDX-AI-Disclosure: none

import 'package:ignis/src/core.dart';
import 'package:ignis/src/message.dart';

/// A component that emits [TimerTrigger] every [interval] seconds.
class TimerComponent extends Component {
  /// How often [TimerTrigger] emits, in seconds.
  double interval;

  /// Whether the timer triggers indefinitely, overriding [count]. Defaults to
  /// false.
  bool repeat;

  /// How many times to trigger before finishing. Defaults to 1.
  ///
  /// Ignored while [repeat] is true.
  int count;

  /// Whether to [detach] once finished. Defaults to false.
  ///
  /// Ignored while [repeat] is true, since an indefinitely repeating timer
  /// never finishes.
  bool cleanup;

  double _elapsed = 0;
  int _triggers = 0;
  bool _finished = false;

  /// The total time this timer has seen.
  double get elapsed => _elapsed;

  /// The number of times the timer has triggered.
  int get triggers => _triggers;

  /// Whether the timer has finished. Always false while [repeat] is true.
  bool get isFinished => _finished;

  TimerComponent({
    required this.interval,
    bool? repeat,
    int? count,
    bool? cleanup,
    super.id,
    super.enabled,
    super.priority,
  }) : assert(interval > 0, 'Interval must be positive.'),
       repeat = repeat ?? false,
       count = count ?? 1,
       cleanup = cleanup ?? false;

  /// Resets the timer back to its start, without triggering.
  void reset() {
    _elapsed = 0;
    _triggers = 0;
    _finished = false;
  }

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Update(:final dt):
        if (_finished) break;
        _elapsed += dt;

        while (_elapsed >= interval) {
          _elapsed -= interval;
          entity.post(TimerTrigger(this));
          if (repeat) continue;

          _triggers += 1;
          if (_triggers < count) continue;

          _finished = true;
          _elapsed = 0;
          if (cleanup) detach();
          break;
        }
    }
  }
}

/// Emitted every time [TimerComponent.interval] seconds elapse on [timer].
final class TimerTrigger extends Message {
  final TimerComponent timer;

  const TimerTrigger(this.timer);
}
