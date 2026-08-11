import 'dart:ui';

import 'package:ignis/src/effects/controlled_effect.dart';

/// An effect that animates a [Paint]'s opacity by mutating its alpha.
class ColorOpacityEffect extends ControlledEffect {
  /// The paint whose alpha channel is mutated as this effect progresses.
  final Paint paint;

  /// Fades [paint] in from fully transparent to fully opaque.
  ColorOpacityEffect.fadeIn({
    required this.paint,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    onProgress((progress) {
      paint.color = paint.color.withValues(alpha: progress);
    });
  }

  /// Fades [paint] out from fully opaque to fully transparent.
  ColorOpacityEffect.fadeOut({
    required this.paint,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    onProgress((progress) {
      paint.color = paint.color.withValues(alpha: 1 - progress);
    });
  }

  /// Shifts [paint]'s opacity by [opacity], relative to its alpha when this
  /// effect starts.
  ColorOpacityEffect.by({
    required this.paint,
    required double opacity,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    late double initial;

    onMount(() {
      initial = paint.color.a;
    });

    onProgress((progress) {
      paint.color = paint.color.withValues(alpha: initial + opacity * progress);
    });
  }
}
