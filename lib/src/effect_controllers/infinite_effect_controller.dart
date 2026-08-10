import 'package:ignis/src/effect_controller.dart';

/// Runs [child] forever, restarting it from the beginning after each run.
class InfiniteEffectController extends EffectController {
  /// The controller to run infinitely.
  final EffectController child;

  InfiniteEffectController(this.child) : super.empty();

  @override
  double? get duration => double.infinity;

  @override
  bool get hasStarted => child.hasStarted;

  @override
  bool get isFinished => false;

  @override
  double get progress => child.progress;

  @override
  double advance(double dt) {
    var remaining = dt;

    while (true) {
      remaining = child.advance(remaining);
      if (remaining == 0) break;
      child.setToStart();
    }

    return 0;
  }

  @override
  double recede(double dt) {
    var remaining = dt;

    while (true) {
      remaining = child.recede(remaining);
      if (remaining == 0) break;
      child.setToEnd();
    }

    return 0;
  }

  @override
  void setToStart() => child.setToStart();

  @override
  void setToEnd() => child.setToEnd();
}
