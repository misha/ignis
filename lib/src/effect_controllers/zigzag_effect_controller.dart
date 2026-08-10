import 'package:ignis/src/effect_controllers/duration_effect_controller.dart';

/// Oscillates progress as a triangle wave between -1 and 1, completing one
/// full cycle every [period].
class ZigzagEffectController extends DurationEffectController {
  final double _quarterPeriod;

  ZigzagEffectController({
    required double period,
  }) : assert(period > 0, 'Period must be positive.'),
       _quarterPeriod = period / 4,
       super(period);

  double get period => duration;

  @override
  double get progress {
    final x = elapsed / _quarterPeriod;

    return switch (x) {
      <= 1 => x,
      >= 3 => x - 4,
      _ => 2 - x,
    };
  }
}
