import 'package:ignis/src/effect_controllers/duration_effect_controller.dart';

/// Waits [duration] before counting as started. Used as a one-time delay
/// before the rest of a sequence begins.
class DelayEffectController extends DurationEffectController {
  DelayEffectController(super.duration);

  @override
  bool get hasStarted => isFinished;

  @override
  double get progress => 0;
}
