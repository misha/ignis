import 'dart:ui';

import 'package:ignis/src/effects/nodes/controlled_effect.dart';

/// An effect that animates a [Paint]'s opacity by mutating its alpha.
///
/// Every variant is the same line - `base + span * progress` - so the
/// constructors differ only in what they put in those two fields. A null
/// [_base] means the alpha is read when the effect builds rather than being
/// fixed up front.
class ColorOpacityEffect extends ControlledEffect {
  /// The paint whose alpha channel is mutated as this effect progresses.
  final Paint paint;

  final double? _base;
  final double _span;

  /// Fades [paint] in from fully transparent to fully opaque.
  ColorOpacityEffect.fadeIn({
    required this.paint,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : _base = 0,
       _span = 1;

  /// Fades [paint] out from fully opaque to fully transparent.
  ColorOpacityEffect.fadeOut({
    required this.paint,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : _base = 1,
       _span = -1;

  /// Shifts [paint]'s opacity by [opacity], relative to its alpha when this
  /// effect starts.
  ColorOpacityEffect.by({
    required this.paint,
    required double opacity,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : _base = null,
       _span = opacity;

  @override
  void build() {
    super.build();
    final base = _base ?? paint.color.a;

    onProgress((progress) {
      paint.color = paint.color.withValues(alpha: base + _span * progress);
    });
  }
}
