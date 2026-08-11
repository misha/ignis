import 'dart:ui';

import 'package:ignis/src/effects/controlled_effect.dart';

/// An effect that fades a [color] in or out on a [Paint] by animating a
/// [ColorFilter], varying [color]'s alpha with progress.
class ColorFilterOpacityEffect extends ControlledEffect {
  /// The paint whose [Paint.colorFilter] is mutated as this effect progresses.
  final Paint paint;

  /// The color applied via [ColorFilter.mode].
  final Color color;

  /// Fades [color] in on [paint] from fully transparent to fully opaque.
  ColorFilterOpacityEffect.fadeIn({
    required this.paint,
    required this.color,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    onProgress((progress) {
      paint.colorFilter = .mode(color.withValues(alpha: color.a * progress), .srcIn);
    });
  }

  /// Fades [color] out on [paint] from fully opaque to fully transparent.
  ColorFilterOpacityEffect.fadeOut({
    required this.paint,
    required this.color,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    onProgress((progress) {
      paint.colorFilter = .mode(color.withValues(alpha: color.a * (1 - progress)), .srcIn);
    });
  }

  /// Shifts a [color]-tinted `ColorFilter` on [paint] by [color]'s alpha,
  /// relative to its intensity when this effect starts advancing.
  ///
  /// Unlike [fadeIn]/[fadeOut], this tracks its own running alpha rather than
  /// reading it back from [paint], since a [ColorFilter] doesn't expose one.
  ColorFilterOpacityEffect.by({
    required this.paint,
    required this.color,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    var alpha = 0.0;

    onProgress((progress) {
      alpha += color.a * (progress - previousProgress);
      paint.colorFilter = .mode(color.withValues(alpha: alpha), .srcIn);
    });
  }
}
