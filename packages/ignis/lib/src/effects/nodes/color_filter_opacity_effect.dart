// SPDX-AI-Disclosure: none

import 'dart:ui';

import 'package:ignis/src/effects/nodes/timeline_effect.dart';

/// An effect that fades a [color] in or out on a [Paint] by animating a
/// [ColorFilter], varying [color]'s alpha with progress.
class ColorFilterOpacityEffect extends TimelineEffect {
  /// The paint whose [Paint.colorFilter] is mutated as this effect progresses.
  final Paint paint;

  /// The color applied via [ColorFilter.mode].
  final Color color;

  final double? _from;
  final double? _to;

  /// Fades [color] in on [paint] from fully transparent to fully opaque.
  ColorFilterOpacityEffect.fadeIn({
    required this.paint,
    required this.color,
    required super.timeline,
    super.cleanup,
    super.enabled,
  }) : _from = 0,
       _to = null;

  /// Fades [color] out on [paint] from fully opaque to fully transparent.
  ColorFilterOpacityEffect.fadeOut({
    required this.paint,
    required this.color,
    required super.timeline,
    super.cleanup,
    super.enabled,
  }) : _from = null,
       _to = 0;

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
    required super.timeline,
    super.cleanup,
    super.enabled,
  }) : _from = fromAlpha ?? 0,
       _to = toAlpha;

  @override
  void build() {
    super.build();
    final from = _from ?? color.a;
    final to = _to ?? color.a;

    onProgress((progress) {
      paint.colorFilter = .mode(color.withValues(alpha: from + (to - from) * progress), .srcIn);
    });
  }
}
