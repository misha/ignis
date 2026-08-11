import 'dart:ui';

import 'package:ignis/src/effect_controller.dart';
import 'package:ignis/src/effects/controlled_effect.dart';

/// An effect that fades a glow in or out on a [Paint] by animating a blurred
/// [ImageFilter], varying its blur sigma between zero and [strength].
abstract class ImageFilterGlowEffect extends ControlledEffect {
  /// The paint whose [Paint.imageFilter] is mutated as this effect progresses.
  final Paint paint;

  /// The blur sigma at full progress.
  final double strength;

  /// Fades a glow in on [paint] from no blur to [strength].
  factory ImageFilterGlowEffect.fadeIn({
    required Paint paint,
    required double strength,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _ImageFilterGlowFadeInEffect;

  /// Fades a glow out on [paint] from [strength] to no blur.
  factory ImageFilterGlowEffect.fadeOut({
    required Paint paint,
    required double strength,
    required EffectController controller,
    bool? cleanup,
    bool? enabled,
  }) = _ImageFilterGlowFadeOutEffect;

  ImageFilterGlowEffect._({
    required this.paint,
    required this.strength,
    required super.controller,
    super.cleanup,
    super.enabled,
  });
}

class _ImageFilterGlowFadeInEffect extends ImageFilterGlowEffect {
  _ImageFilterGlowFadeInEffect({
    required super.paint,
    required super.strength,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : super._() {
    onProgress((progress) {
      final sigma = strength * progress;
      paint.imageFilter = .blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: .decal,
      );
    });
  }
}

class _ImageFilterGlowFadeOutEffect extends ImageFilterGlowEffect {
  _ImageFilterGlowFadeOutEffect({
    required super.paint,
    required super.strength,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) : super._() {
    onProgress((progress) {
      final sigma = strength * (1 - progress);
      paint.imageFilter = .blur(
        sigmaX: sigma,
        sigmaY: sigma,
        tileMode: .decal,
      );
    });
  }
}
