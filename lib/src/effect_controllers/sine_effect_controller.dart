import 'dart:math' as math;

import 'package:ignis/src/effect_controllers/duration_effect_controller.dart';

/// Oscillates progress as a sine wave between -1 and 1, completing one full
/// cycle every [period].
class SineEffectController extends DurationEffectController {
  SineEffectController({
    required double period,
  }) : assert(period > 0, 'Period must be positive.'),
       super(period);

  double get period => duration;

  @override
  double get progress => math.sin(2 * math.pi * elapsed / period);
}
