import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  const double STRENGTH = 8;

  test('fades a glow in from no blur to full strength', () {
    final paint = Paint();
    final effect = ImageFilterGlowEffect.fadeIn(
      paint: paint,
      strength: STRENGTH,
      controller: .linear(1),
    );

    effect.mount();
    effect.update(0.25);

    expect(
      paint.imageFilter,
      ImageFilter.blur(
        sigmaX: STRENGTH * 0.25,
        sigmaY: STRENGTH * 0.25,
        tileMode: .decal,
      ),
    );

    effect.update(0.75);
    expect(
      paint.imageFilter,
      ImageFilter.blur(
        sigmaX: STRENGTH,
        sigmaY: STRENGTH,
        tileMode: .decal,
      ),
    );
  });

  test('fades a glow out from full strength to no blur', () {
    final paint = Paint();
    final effect = ImageFilterGlowEffect.fadeOut(
      paint: paint,
      strength: STRENGTH,
      controller: .linear(1),
    );

    effect.mount();
    effect.update(0.5);

    expect(
      paint.imageFilter,
      ImageFilter.blur(
        sigmaX: STRENGTH * 0.5,
        sigmaY: STRENGTH * 0.5,
        tileMode: .decal,
      ),
    );

    effect.update(0.5);

    expect(
      paint.imageFilter,
      ImageFilter.blur(
        sigmaX: 0,
        sigmaY: 0,
        tileMode: .decal,
      ),
    );
  });

  test('fades from zero to toStrength by default', () {
    final paint = Paint();
    final effect = ImageFilterGlowEffect.by(
      paint: paint,
      toStrength: STRENGTH,
      controller: .linear(1),
    );

    effect.mount();
    effect.update(0.5);

    expect(
      paint.imageFilter,
      ImageFilter.blur(
        sigmaX: STRENGTH * 0.5,
        sigmaY: STRENGTH * 0.5,
        tileMode: .decal,
      ),
    );

    effect.update(0.5);

    expect(
      paint.imageFilter,
      ImageFilter.blur(
        sigmaX: STRENGTH,
        sigmaY: STRENGTH,
        tileMode: .decal,
      ),
    );
  });

  test('fades from fromStrength to toStrength', () {
    final paint = Paint();
    final effect = ImageFilterGlowEffect.by(
      paint: paint,
      fromStrength: 1,
      toStrength: STRENGTH,
      controller: .linear(1),
    );

    effect.mount();
    effect.update(0.5);

    expect(
      paint.imageFilter,
      ImageFilter.blur(
        sigmaX: 1 + (STRENGTH - 1) * 0.5,
        sigmaY: 1 + (STRENGTH - 1) * 0.5,
        tileMode: .decal,
      ),
    );
  });
}
