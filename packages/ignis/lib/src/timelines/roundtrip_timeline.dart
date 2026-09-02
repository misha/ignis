// SPDX-AI-Disclosure: ai-assisted

import 'dart:math' as math;

import 'package:ignis/src/timeline.dart';

/// Plays [child] forward, then back down to its start, using it as a single
/// shared instance for both legs.
class RoundtripTimeline extends Timeline {
  /// The timeline played there and back.
  final Timeline child;

  final double _legDuration;
  double _legElapsed = 0;
  bool _reversed = false;
  bool _finished = false;

  RoundtripTimeline(this.child)
    : assert(
        child.duration?.isFinite ?? false,
        'Cannot round-trip a timeline with an unknown or infinite duration.',
      ),
      _legDuration = child.duration!;

  @override
  void fit(double distance) => child.fit(distance);

  @override
  double? get duration => _legDuration * 2;

  @override
  bool get hasStarted => true;

  @override
  bool get isFinished => _finished;

  @override
  double get progress => child.progress;

  @override
  double advance(double dt) {
    assert(dt >= 0, 'Delta time cannot be negative.');
    var remaining = dt;

    if (!_reversed) {
      final step = math.min(remaining, _legDuration - _legElapsed);
      child.advance(step);
      _legElapsed += step;
      remaining -= step;

      if (_legElapsed < _legDuration) return 0;

      _reversed = true;
      _legElapsed = 0;
    }

    final step = math.min(remaining, _legDuration - _legElapsed);
    child.recede(step);
    _legElapsed += step;
    remaining -= step;

    if (_legElapsed >= _legDuration) _finished = true;

    return remaining;
  }

  @override
  double recede(double dt) {
    assert(dt >= 0, 'Delta time cannot be negative.');
    var remaining = dt;
    _finished = false;

    if (_reversed) {
      final step = math.min(remaining, _legElapsed);
      child.advance(step);
      _legElapsed -= step;
      remaining -= step;

      if (_legElapsed > 0) return remaining;

      _reversed = false;
      _legElapsed = _legDuration;
    }

    final step = math.min(remaining, _legElapsed);
    child.recede(step);
    _legElapsed -= step;
    remaining -= step;

    return remaining;
  }

  @override
  void setToStart() {
    child.setToStart();
    _legElapsed = 0;
    _reversed = false;
    _finished = false;
  }

  @override
  void setToEnd() {
    child.setToStart();
    _legElapsed = _legDuration;
    _reversed = true;
    _finished = true;
  }
}
