import 'package:ignis/src/effect_controllers/duration_effect_controller.dart';

/// Holds [progress] constant for [duration], without moving it. Used as a
/// generic mid-sequence hold, e.g. in place of a top or bottom delay.
class PauseEffectController extends DurationEffectController {
  @override
  final double progress;

  PauseEffectController(
    super.duration, {
    this.progress = 1,
  });
}
