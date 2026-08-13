import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:ignis/src/rng.dart';

/// Progresses through [samples] smoothed random values between -1 and 1,
/// evenly spaced across the unit interval.
class NoiseCurve extends Curve {
  /// How many random samples to interpolate between across the curve.
  final int samples;

  final List<double> _frames;

  NoiseCurve(
    this.samples, {
    Random? random,
  }) : assert(samples > 0, 'Samples must be positive.'),
       _frames = List.generate(
         samples + 2,
         (_) => (random ?? rng).nextDouble() * 2 - 1,
         growable: false,
       );

  @override
  double transform(double t) {
    final sampleT = t * samples;
    final index = sampleT.floor().clamp(0, _frames.length - 2);
    final localT = (sampleT - index).clamp(0.0, 1.0);
    final smooth = localT * localT * (3 - 2 * localT);
    return _frames[index] + (_frames[index + 1] - _frames[index]) * smooth;
  }
}
