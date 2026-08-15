import 'dart:ui';

import 'package:ignis/src/effects/nodes/controlled_effect.dart';

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

  /// Fades a [color]-tinted `ColorFilter` on [paint] from [fromAlpha]
  /// [toAlpha]. If [fromAlpha] is not supplied, it animates from zero.
  ///
  /// Unlike [fadeIn]/[fadeOut], this doesn't derive its endpoints from
  /// [color]'s own alpha, since a [ColorFilter] can't be read back from
  /// [paint] to resolve them automatically.
  ColorFilterOpacityEffect.by({
    required this.paint,
    required this.color,
    double? fromAlpha,
    required double toAlpha,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    final from = fromAlpha ?? 0;

    onProgress((progress) {
      paint.colorFilter = .mode(
        color.withValues(alpha: from + (toAlpha - from) * progress),
        .srcIn,
      );
    });
  }
}
