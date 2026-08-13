import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  const COLOR = Color(0xFFFFCC00);

  test('fades a color filter in from nothing to full intensity', () {
    final paint = Paint();
    final effect = ColorFilterOpacityEffect.fadeIn(
      paint: paint,
      color: COLOR,
      controller: .duration(1),
    );

    effect.mount();
    effect.update(0.25);
    expect(paint.colorFilter, ColorFilter.mode(COLOR.withValues(alpha: 0.25), .srcIn));

    effect.update(0.75);
    expect(paint.colorFilter, ColorFilter.mode(COLOR, .srcIn));
  });

  test('fades a color filter out from full intensity to nothing', () {
    final paint = Paint();
    final effect = ColorFilterOpacityEffect.fadeOut(
      paint: paint,
      color: COLOR,
      controller: .duration(1),
    );

    effect.mount();
    effect.update(0.5);
    expect(paint.colorFilter, ColorFilter.mode(COLOR.withValues(alpha: 0.5), .srcIn));

    effect.update(0.5);
    expect(paint.colorFilter, ColorFilter.mode(COLOR.withValues(alpha: 0), .srcIn));
  });

  test('scales intensity by the given color\'s own alpha', () {
    final paint = Paint();
    final effect = ColorFilterOpacityEffect.fadeIn(
      paint: paint,
      color: COLOR.withValues(alpha: 0.5),
      controller: .duration(1),
    );

    effect.mount();
    effect.update(1);
    expect(paint.colorFilter, ColorFilter.mode(COLOR.withValues(alpha: 0.5), .srcIn));
  });

  test('fades from 0 to toAlpha by default', () {
    final paint = Paint();
    final effect = ColorFilterOpacityEffect.by(
      paint: paint,
      color: COLOR,
      toAlpha: 0.4,
      controller: .duration(1),
    );

    effect.mount();
    effect.update(0.5);
    expect(paint.colorFilter, ColorFilter.mode(COLOR.withValues(alpha: 0.2), .srcIn));

    effect.update(0.5);
    expect(paint.colorFilter, ColorFilter.mode(COLOR.withValues(alpha: 0.4), .srcIn));
  });

  test('fades from fromAlpha to toAlpha', () {
    final paint = Paint();
    final effect = ColorFilterOpacityEffect.by(
      paint: paint,
      color: COLOR,
      fromAlpha: 0.1,
      toAlpha: 0.5,
      controller: .duration(1),
    );

    effect.mount();
    effect.update(0.5);

    expect(
      paint.colorFilter,
      ColorFilter.mode(COLOR.withValues(alpha: 0.1 + (0.5 - 0.1) * 0.5), .srcIn),
    );
  });
}
