import 'package:flutter/animation.dart';
import 'package:flutter/foundation.dart';

const _FLAG_REPEAT = 1 << 0;
const _FLAG_FINISH = 1 << 1;
const _FLAG_RESET = 1 << 2;

final class EffectControllerResult {
  @visibleForTesting
  EffectControllerResult({
    this._progress = 0,
    bool repeat = false,
    bool finish = false,
    bool reset = false,
  }) {
    if (repeat) _flags |= _FLAG_REPEAT;
    if (finish) _flags |= _FLAG_FINISH;
    if (reset) _flags |= _FLAG_RESET;
  }

  double _progress;
  int _flags = 0;

  double get progress => _progress;
  bool get repeat => _flags & _FLAG_REPEAT != 0;
  bool get finish => _flags & _FLAG_FINISH != 0;
  bool get reset => _flags & _FLAG_RESET != 0;

  void _recycle() {
    _progress = 0;
    _flags = 0;
  }

  @override
  bool operator ==(Object other) =>
      other is EffectControllerResult && //
      _progress == other._progress &&
      _flags == other._flags;

  @override
  int get hashCode => Object.hash(_progress, _flags);

  @override
  String toString() =>
      'EffectControllerResult('
      'progress=$progress, '
      'repeat=$repeat, '
      'finish=$finish, '
      '$reset=reset'
      ')';
}

/// Drives a controlled effect's timing and progress.
///
/// The main implementation is the [EffectController], directly inspired by
/// Flame's `EffectController`. It can be configured to repeat, reverse, and
/// so forth automatically, on a preset track.
///
/// There is another controller for effects that must respond to unpredictable
/// events: [ManualEffectController]. While it lacks some of the features of its
/// automatic counterpart, the manual controller can freely play in either
/// direction at any time, making it ideal for unscripted timelines.
abstract class BaseEffectController {
  /// This controller's current progress. Typically 0 to 1, though some curves
  /// briefly go outside that range (e.g. a "bouncy" easing curve).
  double get progress;

  /// Whether this controller has started progressing yet.
  bool get hasStarted;

  final EffectControllerResult _result = .new();

  /// Advances this controller's clock by [dt].
  ///
  /// The returned result explains everything that happened as a result of the
  /// update. The result is owned by this controller and should not be retained.
  EffectControllerResult update(double dt) {
    _result._recycle();
    tick(dt, _result);
    return _result;
  }

  @visibleForOverriding
  void tick(double dt, EffectControllerResult result);

  /// Reverts this controller to its initial state.
  void reset();
}

// TODO: Document this.
class EffectController extends BaseEffectController {
  /// How long to run the effect from start to finish.
  final double duration;

  /// The curve to use when progressing the effect. Defaults to [Curves.linear].
  final Curve curve;

  /// How long to wait before starting the effect. Defaults to 0.
  final double startDelay;

  /// How many times to run before [isFinished] stays true for good. Defaults
  /// to 1. Set to null to repeat forever.
  final int? times;

  /// Whether to run back from finish to start after reaching the end,
  /// before counting as one repeat. Defaults to false.
  final bool reverse;

  /// How long the reverse phase takes, when [reverse] is true.
  /// Defaults to [duration].
  final double reverseDuration;

  /// The curve to use for the reverse phase, when [reverse] is true.
  /// Defaults to [curve].
  final Curve reverseCurve;

  /// How long to pause at the end before the reverse phase starts, when
  /// [reverse] is true. Defaults to 0.
  final double reverseDelay;

  late final double _totalDuration;
  double _elapsed = 0;
  int _repeats = 0;

  @override
  bool get hasStarted => _elapsed >= 0;

  /// Whether or not this effect has finished.
  bool get isFinished => _elapsed >= _totalDuration;

  /// Whether another repeat remains once the current one finishes.
  bool get canRepeat => times == null || _repeats + 1 < times!;

  EffectController({
    required this.duration,
    this.curve = Curves.linear,
    this.startDelay = 0,
    this.times = 1,
    bool? reverse,
    double? reverseDuration,
    Curve? reverseCurve,
    this.reverseDelay = 0,
  }) : assert(duration > 0, 'Duration must be positive.'),
       assert(startDelay >= 0, 'Start delay cannot be negative.'),
       assert(times == null || times > 0, 'Times must be positive.'),
       assert(reverseDuration == null || reverseDuration > 0, 'Reverse duration must be positive.'),
       assert(reverseDelay >= 0, 'Reverse delay cannot be negative.'),
       reverse = reverse ?? false,
       reverseDuration = reverseDuration ?? duration,
       reverseCurve = reverseCurve ?? curve,
       _elapsed = -startDelay {
    var totalDuration = duration;
    if (this.reverse) totalDuration += reverseDelay + this.reverseDuration;
    _totalDuration = totalDuration;
  }

  @override
  double get progress {
    if (!hasStarted) return 0;
    if (_elapsed <= duration) return curve.transform(_elapsed / duration);
    if (_elapsed <= duration + reverseDelay) return 1;
    return 1 - reverseCurve.transform((_elapsed - duration - reverseDelay) / reverseDuration);
  }

  @override
  void tick(dt, result) {
    assert(dt >= 0, 'Delta time cannot be negative.');
    _elapsed += dt;
    var overflow = 0.0;

    if (_elapsed > _totalDuration) {
      overflow = _elapsed - _totalDuration;
      _elapsed = _totalDuration;
    }

    if (!hasStarted) return;
    result._progress = progress;

    if (isFinished) {
      if (canRepeat) {
        _repeats += 1;
        _elapsed = -startDelay + overflow;
        result._flags |= _FLAG_REPEAT;
        return;
      }

      result._flags |= _FLAG_FINISH;
      return;
    }

    return;
  }

  @override
  void reset() {
    _elapsed = -startDelay;
    _repeats = 0;
  }
}

/// Runs on demand, freely moving in whichever direction [play] demands.
///
/// Unlike [EffectController], it cannot repeat, run a specific number
/// of times, or run in reverse automatically. Instead, it's up to the user to
/// configure those behaviors as necessary. In return, it's also more flexible
/// when responding to unpredictable events, like collisions or user input.
class ManualEffectController extends BaseEffectController {
  /// The duration a full run from [position] 0 to 1 would take.
  final double duration;

  /// The curve to use while playing toward a higher position.
  /// Defaults to [Curves.linear].
  final Curve curve;

  /// The curve to use while playing toward a lower position.
  /// Defaults to [curve].
  final Curve reverseCurve;

  double _elapsed = 0;
  double? _target;
  bool _forward = true;

  ManualEffectController({
    required this.duration,
    this.curve = Curves.linear,
    Curve? reverseCurve,
  }) : assert(duration > 0, 'Duration must be positive.'),
       reverseCurve = reverseCurve ?? curve;

  /// This controller's current position, as a fraction of [duration].
  ///
  /// [progress] is simply this value transformed by the current curve.
  double get position => _elapsed / duration;

  @override
  double get progress {
    if (_forward) {
      return curve.transform(position);
    } else {
      return reverseCurve.transform(position);
    }
  }

  @override
  bool get hasStarted => true;

  /// Jumps directly to [position], with no interpolation.
  void seek(double position) => _elapsed = position * duration;

  /// Plays toward [to], starting from [from] if given.
  void play({
    double? from,
    required double to,
  }) {
    if (from != null) seek(from);
    _target = to;
  }

  @override
  void tick(dt, result) {
    final target = _target;
    if (target == null) return;

    final targetElapsed = target * duration;
    _forward = _elapsed <= targetElapsed;
    _elapsed += _forward ? dt : -dt;

    if ((_forward && _elapsed > targetElapsed) || //
        (!_forward && _elapsed < targetElapsed)) {
      _elapsed = targetElapsed;
    }

    result._progress = progress;
    if (_elapsed == targetElapsed) result._flags |= _FLAG_FINISH;
    if (!_forward) result._flags |= _FLAG_RESET; // This can't be right.
  }

  @override
  void reset() {
    _elapsed = 0;
    _target = null;
    _forward = true;
  }
}
