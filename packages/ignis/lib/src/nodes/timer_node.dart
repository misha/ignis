import 'package:ignis/src/core.dart';

/// A node that emits [onTrigger] every [interval] seconds.
class TimerNode extends Node {
  /// How often [onTrigger] emits, in seconds.
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

  /// Emitted every time [interval] seconds elapse.
  final onTrigger = Signal0();

  double _elapsed = 0;
  int _triggers = 0;
  bool _finished = false;

  /// The total time this timer has seen.
  double get elapsed => _elapsed;

  /// The number of times the timer has triggered.
  int get triggers => _triggers;

  /// Whether the timer has finished. Always false while [repeat] is true.
  bool get isFinished => _finished;

  TimerNode({
    required this.interval,
    bool? repeat,
    int? count,
    bool? cleanup,
    super.enabled,
    super.priority,
    super.children,
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
  void build() {
    super.build();
    tick((dt) {
      if (_finished) return;
      _elapsed += dt;

      while (_elapsed >= interval) {
        _elapsed -= interval;
        onTrigger.emit();
        if (repeat) continue;

        _triggers += 1;
        if (_triggers < count) continue;

        _finished = true;
        _elapsed = 0;
        if (cleanup) detach();
        return;
      }
    });
  }
}
