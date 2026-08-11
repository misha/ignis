import 'dart:ui';

import 'package:ignis/src/effect_controller.dart';
import 'package:ignis/src/effects/controlled_effect.dart';

/// An effect that animates a [Paint]'s opacity by mutating its alpha.
abstract class ColorOpacityEffect extends ControlledEffect {
  /// The paint whose alpha channel is mutated as this effect progresses.
  final Paint paint;

  /// Fades [paint] in from fully transparent to fully opaque.
  factory ColorOpacityEffect.fadeIn({
    required Paint paint,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _ColorOpacityFadeInEffect;

  /// Fades [paint] out from fully opaque to fully transparent.
  factory ColorOpacityEffect.fadeOut({
    required Paint paint,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _ColorOpacityFadeOutEffect;

  ColorOpacityEffect._({
    required this.paint,
    required super.controller,
    super.cleanup,
    super.enabled,
  });
}

class _ColorOpacityFadeInEffect extends ColorOpacityEffect {
  _ColorOpacityFadeInEffect({
    required super.paint,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : super._() {
    onProgress((progress) {
      paint.color = paint.color.withValues(alpha: progress);
    });
  }
}

class _ColorOpacityFadeOutEffect extends ColorOpacityEffect {
  _ColorOpacityFadeOutEffect({
    required super.paint,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : super._() {
    onProgress((progress) {
      paint.color = paint.color.withValues(alpha: 1 - progress);
    });
  }
}
