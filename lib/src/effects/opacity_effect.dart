import 'dart:ui';

import 'package:ignis/src/nodes/effect_node.dart';

/// An [EffectNode] that animates a [Paint]'s opacity by mutating its alpha.
abstract class OpacityEffect extends EffectNode {
  /// The paint whose alpha channel is mutated as this effect progresses.
  final Paint paint;

  /// Fades [paint] in from fully transparent to fully opaque.
  factory OpacityEffect.fadeIn({
    required Paint paint,
    required EffectController controller,
    bool? cleanup,
  }) = _FadeInEffect;

  /// Fades [paint] out from fully opaque to fully transparent.
  factory OpacityEffect.fadeOut({
    required Paint paint,
    required EffectController controller,
    bool? cleanup,
  }) = _FadeOutEffect;

  OpacityEffect._({
    required this.paint,
    required super.controller,
    super.cleanup,
  });
}

class _FadeInEffect extends OpacityEffect {
  _FadeInEffect({
    required super.paint,
    required super.controller,
    super.cleanup,
  }) : super._() {
    onProgress((progress) {
      paint.color = paint.color.withValues(alpha: progress);
    });
  }
}

class _FadeOutEffect extends OpacityEffect {
  _FadeOutEffect({
    required super.paint,
    required super.controller,
    super.cleanup,
  }) : super._() {
    onProgress((progress) {
      paint.color = paint.color.withValues(alpha: 1 - progress);
    });
  }
}
