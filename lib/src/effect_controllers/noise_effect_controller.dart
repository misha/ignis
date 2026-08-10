import 'dart:math';

import 'package:ignis/src/effect_controllers/duration_effect_controller.dart';
import 'package:ignis/src/rng.dart';

/// Progresses through smoothed random noise between -1 and 1, sampling a new
/// random value [frequency] times per second and smoothly interpolating
/// between them.
class NoiseEffectController extends DurationEffectController {
  /// How many random samples to generate per second. Defaults to 1.
  final double frequency;

  late final List<double> _frames;

  NoiseEffectController(
    super.duration, {
    this.frequency = 1,
    Random? random,
  }) : assert(frequency > 0, 'Frequency must be positive.') {
    random ??= rng;
    _frames = List.generate(
      (duration * frequency).ceil() + 2,
      (_) => random!.nextDouble() * 2 - 1,
      growable: false,
    );
  }

  @override
  double get progress {
    final t = elapsed * frequency;
    final index = t.floor().clamp(0, _frames.length - 2);
    final localT = (t - index).clamp(0.0, 1.0);
    final smooth = localT * localT * (3 - 2 * localT);
    return _frames[index] + (_frames[index + 1] - _frames[index]) * smooth;
  }
}
