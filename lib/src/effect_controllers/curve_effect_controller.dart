import 'package:flutter/animation.dart';
import 'package:ignis/src/effect_controllers/duration_effect_controller.dart';

/// Progresses from 0 to 1 over [duration], shaped by [curve]. Runs from 1
/// down to 0 instead, when [reverse] is true.
class CurveEffectController extends DurationEffectController {
  /// The curve to shape progress with.
  final Curve curve;

  /// Whether to run from 1 down to 0, instead of 0 up to 1. Defaults to false.
  final bool reverse;

  CurveEffectController(
    super.duration,
    this.curve, {
    bool? reverse,
  }) : assert(duration > 0, 'Duration must be positive.'),
       reverse = reverse ?? false;

  @override
  double get progress => curve.transform(reverse ? 1 - elapsed / duration : elapsed / duration);
}
