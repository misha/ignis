import 'package:flutter/animation.dart';
import 'package:ignis/src/effect_controllers/duration_effect_controller.dart';

/// Progresses from 0 to 1 over [duration], shaped by [curve].
class CurveEffectController extends DurationEffectController {
  /// The curve to shape progress with.
  final Curve curve;

  CurveEffectController(
    super.duration, {
    required this.curve,
  }) : assert(duration > 0, 'Duration must be positive.');

  @override
  double get progress => curve.transform(elapsed / duration);
}
