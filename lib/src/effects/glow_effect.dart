import 'dart:ui';

import 'package:ignis/src/effect_controller.dart';
import 'package:ignis/src/effects/controlled_effect.dart';

/// An effect that fades a glow [ColorFilter] in or out on a [Paint], by
/// varying [color]'s alpha with progress.
///
/// Captures [paint]'s existing [Paint.colorFilter] on mount, and restores it
/// on unmount. This lets glow effects be sequenced in time on the same
/// [Paint] without permanently clobbering whatever filter was there before,
/// even though they can't run simultaneously as [Paint] only has one filter.
abstract class GlowEffect extends ControlledEffect {
  /// The paint whose color filter is mutated as this effect progresses.
  final Paint paint;

  /// The glow's color. Its own alpha caps how intense the glow gets.
  final Color color;

  /// Fades a glow of [color] in on [paint], from nothing to full intensity.
  factory GlowEffect.fadeIn({
    required Paint paint,
    required Color color,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _GlowInEffect;

  /// Fades a glow of [color] out on [paint], from full intensity to nothing.
  factory GlowEffect.fadeOut({
    required Paint paint,
    required Color color,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _GlowOutEffect;

  GlowEffect._({
    required this.paint,
    required this.color,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    ColorFilter? saved;

    onMount(() {
      saved = paint.colorFilter;
    });

    onUnmount(() {
      paint.colorFilter = saved;
    });
  }
}

class _GlowInEffect extends GlowEffect {
  _GlowInEffect({
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

class _GlowOutEffect extends GlowEffect {
  _GlowOutEffect({
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
