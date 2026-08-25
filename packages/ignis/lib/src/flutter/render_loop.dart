// SPDX-AI-Disclosure: none

import 'package:flutter/foundation.dart';
import 'package:flutter/scheduler.dart';

/// Drives a rendering by calling [callback] on every Flutter animation frame.
///
/// After creating a [RenderLoop], call [start] to make it actually run. When a
/// [RenderLoop] is no longer needed, it must be [dispose]d.
@internal
class RenderLoop {
  /// Called on every Flutter rendering frame with the number of seconds
  /// elapsed since the previous invocation. Equal to zero on first invocation.
  void Function(double dt) callback;

  late final _ticker = Ticker(_tick);
  Duration _previous = .zero;

  /// Whether the loop is currently ticking.
  bool get isRunning => _ticker.isActive;

  RenderLoop(this.callback);

  void _tick(Duration timestamp) {
    final delta = timestamp - _previous;
    final dt = delta.inMicroseconds / Duration.microsecondsPerSecond;
    _previous = timestamp;
    callback(dt);
  }

  /// Starts the loop. Created in a paused state, so this must be called once
  /// to make it run. Calling this again while already running is a no-op.
  void start() {
    if (!_ticker.isActive) _ticker.start();
  }

  /// Stops the loop. Time freezes while stopped; resuming will not report the
  /// elapsed downtime to [callback].
  void stop() {
    _ticker.stop();
    _previous = .zero;
  }

  /// Call this before discarding the [RenderLoop].
  void dispose() => _ticker.dispose();
}
