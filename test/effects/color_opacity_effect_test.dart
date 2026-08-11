import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  const EPSILON = 1e-6;
  const COLOR = Color(0xFF336699);

  test('fades a paint in from transparent to opaque', () {
    final paint = Paint()..color = COLOR;
    final effect = ColorOpacityEffect.fadeIn(paint: paint, controller: .linear(1));
    effect.mount();

    effect.update(0.25);
    expect(paint.color.a, closeTo(0.25, EPSILON));

    effect.update(0.75);
    expect(paint.color.a, closeTo(1, EPSILON));
    expect(paint.color.r, closeTo(COLOR.r, EPSILON));
    expect(paint.color.g, closeTo(COLOR.g, EPSILON));
    expect(paint.color.b, closeTo(COLOR.b, EPSILON));
  });

  test('fades a paint out from opaque to transparent', () {
    final paint = Paint()..color = COLOR;
    final effect = ColorOpacityEffect.fadeOut(paint: paint, controller: .linear(1));
    effect.mount();

    effect.update(0.5);
    expect(paint.color.a, closeTo(0.5, EPSILON));

    effect.update(0.5);
    expect(paint.color.a, closeTo(0, EPSILON));
  });

  test('shifts a paint\'s opacity by a total amount, relative to its starting alpha', () {
    final paint = Paint()..color = COLOR.withValues(alpha: 0.2);
    final effect = ColorOpacityEffect.by(paint: paint, opacity: 0.5, controller: .linear(1));
    effect.mount();

    effect.update(0.5);
    expect(paint.color.a, closeTo(0.45, EPSILON));

    effect.update(0.5);
    expect(paint.color.a, closeTo(0.7, EPSILON));
  });

  test('seeds its starting alpha from the paint when it mounts, not when constructed', () {
    final paint = Paint()..color = COLOR.withValues(alpha: 0.2);
    final effect = ColorOpacityEffect.by(paint: paint, opacity: 0.5, controller: .linear(1));

    paint.color = COLOR.withValues(alpha: 0.4); // Changed before mounting.
    effect.mount();

    effect.update(0.5);
    expect(paint.color.a, closeTo(0.65, EPSILON));
  });
}
