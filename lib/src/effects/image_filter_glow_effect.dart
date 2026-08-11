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
      paint.imageFilter = .blur(
        sigmaX: strength * progress,
        sigmaY: strength * progress,
        tileMode: .decal,
      );
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
      paint.imageFilter = .blur(
        sigmaX: strength * (1 - progress),
        sigmaY: strength * (1 - progress),
        tileMode: .decal,
      );
    });
  }

  /// Fades a blurred `ImageFilter` on [paint] from [fromStrength] (defaults
  /// to no blur) to [toStrength].
  ///
  /// Unlike [fadeIn]/[fadeOut], this doesn't derive its start from no blur
  /// implicitly, since an [ImageFilter] can't be read back from [paint] to
  /// resolve it automatically.
  ImageFilterGlowEffect.by({
    required this.paint,
    double? fromStrength,
    required double toStrength,
    required super.controller,
    super.cleanup,
    super.enabled,
  }) {
    final from = fromStrength ?? 0;

    onProgress((progress) {
      paint.imageFilter = .blur(
        sigmaX: from + (toStrength - from) * progress,
        sigmaY: from + (toStrength - from) * progress,
        tileMode: .decal,
      );
    });
  }
}
