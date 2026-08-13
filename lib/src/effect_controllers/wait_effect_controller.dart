import 'package:ignis/src/effect_controllers/duration_effect_controller.dart';

/// Holds progress at 1 for [duration], without moving it. Used as a generic
/// mid-sequence pause.
class WaitEffectController extends DurationEffectController {
  WaitEffectController(super.duration);

  @override
  double get progress => 1;
}
