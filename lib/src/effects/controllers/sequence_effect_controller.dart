import 'package:ignis/src/effects/effect_controller.dart';
import 'package:ignis/src/effects/nodes/controlled_effect.dart';

/// Runs [children] one after another, advancing to the next once the current
/// one finishes.
class SequenceEffectController extends EffectController {
  /// The controllers run in sequence.
  final List<EffectController> children;

  int _currentIndex = 0;

  SequenceEffectController(this.children)
    : assert(children.isNotEmpty, 'At least 1 child is required.'),
      super.empty();

  @override
  void attach(ControlledEffect effect) {
    for (final child in children) {
      child.attach(effect);
    }
  }

  @override
  double? get duration {
    var total = 0.0;

    for (final child in children) {
      final childDuration = child.duration;
      if (childDuration == null) return null;
      total += childDuration;
    }

    return total;
  }

  @override
  bool get hasStarted => children[_currentIndex].hasStarted;

  @override
  bool get isFinished =>
      _currentIndex == children.length - 1 && //
      children[_currentIndex].isFinished;

  @override
  double get progress => children[_currentIndex].progress;

  @override
  double advance(double dt) {
    var overflow = children[_currentIndex].advance(dt);

    while (overflow > 0 && _currentIndex < children.length - 1) {
      _currentIndex += 1;
      overflow = children[_currentIndex].advance(overflow);
    }

    return overflow;
  }

  @override
  double recede(double dt) {
    var remaining = children[_currentIndex].recede(dt);

    while (remaining > 0 && _currentIndex > 0) {
      _currentIndex -= 1;
      remaining = children[_currentIndex].recede(remaining);
    }

    return remaining;
  }

  @override
  void setToStart() {
    _currentIndex = 0;

    for (final child in children) {
      child.setToStart();
    }
  }

  @override
  void setToEnd() {
    _currentIndex = children.length - 1;

    for (final child in children) {
      child.setToEnd();
    }
  }
}
