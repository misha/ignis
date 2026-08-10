import 'package:flutter/animation.dart';
import 'package:ignis/src/effect_controllers/duration_effect_controller.dart';

/// Progresses from 1 down to 0 over [duration], shaped by [curve].
class ReverseCurveEffectController extends DurationEffectController {
  /// The curve to shape progress with.
  final Curve curve;

  ReverseCurveEffectController(
    super.duration, {
    required this.curve,
  }) : assert(duration > 0, 'Duration must be positive.');

  @override
  double get progress => curve.transform(1 - elapsed / duration);
}
