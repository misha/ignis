import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  const EPSILON = 1e-6;
  const COLOR = Color(0xFF336699);

  test('fades a paint in from transparent to opaque', () {
    final paint = Paint()..color = COLOR;
    final effect = OpacityEffect.fadeIn(paint: paint, controller: EffectController(duration: 1));
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
    final effect = OpacityEffect.fadeOut(paint: paint, controller: EffectController(duration: 1));
    effect.mount();

    effect.update(0.5);
    expect(paint.color.a, closeTo(0.5, EPSILON));

    effect.update(0.5);
    expect(paint.color.a, closeTo(0, EPSILON));
  });
}
