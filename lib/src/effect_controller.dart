import 'dart:math';

import 'package:flutter/animation.dart';
import 'package:ignis/src/effect_controllers.dart';
import 'package:ignis/src/effects/controlled_effect.dart';

/// Drives a [ControlledEffect]'s timing and progress.
abstract class EffectController {
  // #region API

  EffectController.empty();

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
  factory EffectController.curve(double duration, Curve curve, {bool reverse}) = CurveEffectController;
  factory EffectController.delay(double duration) = DelayEffectController;
  factory EffectController.infinite(EffectController child) = InfiniteEffectController;
  factory EffectController.linear(double duration) => CurveEffectController(duration, Curves.linear);
  factory EffectController.noise(double duration, {double frequency, Random? random}) = NoiseEffectController;
  factory EffectController.pause(double duration, {double progress}) = PauseEffectController;
  factory EffectController.repeat(EffectController child, int times) = RepeatEffectController;
  factory EffectController.roundtrip(EffectController child) = RoundtripEffectController;
  factory EffectController.sequence(List<EffectController> children) = SequenceEffectController;
  factory EffectController.sine({required double period}) = SineEffectController;
  factory EffectController.zigzag({required double period}) = ZigzagEffectController;
  // dart format on

  // #endregion
}
