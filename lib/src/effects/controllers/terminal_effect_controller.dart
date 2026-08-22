// SPDX-AI-Disclosure: none

import 'package:ignis/src/effects/effect_controller.dart';
import 'package:ignis/src/effects/nodes/controlled_effect.dart';

/// Always finished, at progress 1, consuming no time.
class TerminalEffectController extends EffectController {
  const TerminalEffectController() : super.empty();

  @override
  void attach(ControlledEffect effect) {}

  @override
  double? get duration => 0;

  @override
  bool get hasStarted => true;

  @override
  bool get isFinished => true;

  @override
  double get progress => 1;

  @override
  double advance(double dt) => dt;

  @override
  double recede(double dt) => dt;

  @override
  void setToStart() {}

  @override
  void setToEnd() {}
}
