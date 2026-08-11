import 'dart:ui';

import 'package:ignis/src/effect_controller.dart';
import 'package:ignis/src/effects/controlled_effect.dart';

/// An effect that fades a [color] in or out on a [Paint] by animating a
/// [ColorFilter], varying [color]'s alpha with progress.
abstract class ColorFilterOpacityEffect extends ControlledEffect {
  /// The paint whose [Paint.colorFilter] is mutated as this effect progresses.
  final Paint paint;

  /// The color applied via [ColorFilter.mode].
  final Color color;

  /// Fades [color] in on [paint] from fully transparent to fully opaque.
  factory ColorFilterOpacityEffect.fadeIn({
    required Paint paint,
    required Color color,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _ColorFilterOpacityFadeInEffect;

  /// Fades [color] out on [paint] from fully opaque to fully transparent.
  factory ColorFilterOpacityEffect.fadeOut({
    required Paint paint,
    required Color color,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _ColorFilterOpacityFadeOutEffect;

  ColorFilterOpacityEffect._({
    required this.paint,
    required this.color,
    required super.controller,
    super.cleanup,
    super.enabled,
  });
}

class _ColorFilterOpacityFadeInEffect extends ColorFilterOpacityEffect {
  _ColorFilterOpacityFadeInEffect({
    required super.paint,
    required super.color,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : super._() {
    onProgress((progress) {
      paint.colorFilter = .mode(color.withValues(alpha: color.a * progress), .srcIn);
    });
  }
}

class _ColorFilterOpacityFadeOutEffect extends ColorFilterOpacityEffect {
  _ColorFilterOpacityFadeOutEffect({
    required super.paint,
    required super.color,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : super._() {
    onProgress((progress) {
      paint.colorFilter = .mode(color.withValues(alpha: color.a * (1 - progress)), .srcIn);
    });
  }
}
