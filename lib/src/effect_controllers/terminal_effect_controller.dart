import 'package:ignis/src/effect_controller.dart';
import 'package:ignis/src/effects/controlled_effect.dart';

/// Always finished, at a fixed [progress], consuming no time.
class TerminalEffectController extends EffectController {
  /// This controller's fixed, constant progress. Defaults to 1.
  @override
  final double progress;

  const TerminalEffectController({
    double? progress,
  }) : progress = progress ?? 1,
       super.empty();

  @override
  void attach(ControlledEffect effect) {
    // Nothing to do.
  }

  @override
  double? get duration => 0;

  @override
  bool get hasStarted => true;

  @override
  bool get isFinished => true;

  @override
  double advance(double dt) => dt;

  @override
  double recede(double dt) => dt;

  @override
  void setToStart() {
    // Nothing to do.
  }

  @override
  void setToEnd() {
    // Nothing to do.
  }
}
