// SPDX-AI-Disclosure: none

import 'package:flutter/animation.dart';
import 'package:ignis/src/effects/controllers/duration_effect_controller.dart';
import 'package:ignis/src/effects/controllers/infinite_effect_controller.dart';
import 'package:ignis/src/effects/controllers/once_effect_controller.dart';
import 'package:ignis/src/effects/controllers/repeat_effect_controller.dart';
import 'package:ignis/src/effects/controllers/roundtrip_effect_controller.dart';
import 'package:ignis/src/effects/controllers/sequence_effect_controller.dart';
import 'package:ignis/src/effects/controllers/speed_effect_controller.dart';
import 'package:ignis/src/effects/controllers/terminal_effect_controller.dart';
import 'package:ignis/src/effects/controllers/wait_effect_controller.dart';
import 'package:ignis/src/effects/nodes/controlled_effect.dart';

/// Drives a [ControlledEffect]'s timing and progress.
abstract class EffectController {
  // #region API

  const EffectController.empty();

  /// Called once, when this controller's [effect] is constructed.
  ///
  /// Implementations should generally just propagate this to their child(ren),
  /// unless they have something interesting to do with the effect, as in the
  /// case of the `SpeedEffectController`.
  void attach(ControlledEffect effect);

  /// How long this controller takes to complete, if known. `double.infinity`
  /// if it never completes on its own.
  double? get duration;

  /// Whether [duration] is `double.infinity`.
  bool get isInfinite => duration == double.infinity;

  /// Whether or not this controller has started progressing.
  bool get hasStarted;

  /// Whether or not this controller has finished.
  bool get isFinished;

  /// This controller's current progress.
  double get progress;

  /// Advances this controller's internal clock by [dt], returning any
  /// leftover time once finished.
  double advance(double dt);

  /// The reverse of [advance]: recedes this controller's internal clock by
  /// [dt], returning any leftover time once back at the start.
  double recede(double dt);

  /// Resets this controller back to its start.
  void setToStart();

  /// Jumps this controller straight to its end.
  void setToEnd();

  // #endregion

  // #region Shorthand

  // dart format off
  factory EffectController.duration(double duration, [Curve? curve]) = DurationEffectController;
  factory EffectController.infinite(EffectController child) = InfiniteEffectController;
  factory EffectController.once(EffectController child) = OnceEffectController;
  factory EffectController.repeat(EffectController child, int times) = RepeatEffectController;
  factory EffectController.roundtrip(EffectController child) = RoundtripEffectController;
  factory EffectController.sequence(List<EffectController> children) = SequenceEffectController;
  factory EffectController.speed(double speed, [Curve? curve]) = SpeedEffectController;
  factory EffectController.terminal() = TerminalEffectController;
  factory EffectController.wait(double duration) = WaitEffectController;
  // dart format on

  // #endregion
}
