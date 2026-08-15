import 'package:ignis/src/effects/effect_controller.dart';
import 'package:ignis/src/effects/nodes/controlled_effect.dart';

/// Runs [child] once; ignored after that, whether reversing or repeating.
class OnceEffectController extends EffectController {
  /// The controller run once.
  final EffectController child;

  OnceEffectController(this.child) : super.empty();

  @override
  void attach(ControlledEffect effect) => child.attach(effect);

  @override
  double? get duration => child.duration;

  @override
  bool get hasStarted => child.isFinished;

  @override
  bool get isFinished => child.isFinished;

  @override
  double get progress => child.progress;

  @override
  double advance(double dt) => child.advance(dt);

  @override
  double recede(double dt) => child.isFinished ? dt : child.recede(dt);

  @override
  void setToStart() {
    if (!child.isFinished) child.setToStart();
  }

  @override
  void setToEnd() => child.setToEnd();
}
