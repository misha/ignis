import 'dart:ui';

import 'package:ignis/src/effects/controlled_effect.dart';

/// An effect that fades a glow in or out on a [Paint] by animating a blurred
/// [ImageFilter], varying its blur sigma between zero and a given strength.
class ImageFilterGlowEffect extends ControlledEffect {
  /// The paint whose [Paint.imageFilter] is mutated as this effect progresses.
  final Paint paint;

  /// Fades a glow in on [paint] from no blur to [strength].
  ImageFilterGlowEffect.fadeIn({
    required this.paint,
    required double strength,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    onProgress((progress) {
      final sigma = strength * progress;
      paint.imageFilter = .blur(sigmaX: sigma, sigmaY: sigma, tileMode: .decal);
    });
  }

  /// Fades a glow out on [paint] from [strength] to no blur.
  ImageFilterGlowEffect.fadeOut({
    required this.paint,
    required double strength,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    onProgress((progress) {
      final sigma = strength * (1 - progress);
      paint.imageFilter = .blur(sigmaX: sigma, sigmaY: sigma, tileMode: .decal);
    });
  }

  /// Shifts a blurred `ImageFilter` on [paint] by [strength], relative to its
  /// blur sigma when this effect starts advancing.
  ImageFilterGlowEffect.by({
    required this.paint,
    required double strength,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    var sigma = 0.0;

    onProgress((progress) {
      sigma += strength * (progress - previousProgress);
      paint.imageFilter = .blur(sigmaX: sigma, sigmaY: sigma, tileMode: .decal);
    });
  }
}
