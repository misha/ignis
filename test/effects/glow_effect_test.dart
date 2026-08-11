import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  const COLOR = Color(0xFFFFCC00);

  test('fades a glow in from nothing to full intensity', () {
    final paint = Paint();
    final effect = GlowEffect.fadeIn(paint: paint, color: COLOR, controller: .linear(1));
    effect.mount();

    effect.update(0.25);
    expect(paint.colorFilter, ColorFilter.mode(COLOR.withValues(alpha: 0.25), BlendMode.srcIn));

    effect.update(0.75);
    expect(paint.colorFilter, ColorFilter.mode(COLOR, BlendMode.srcIn));
  });

  test('fades a glow out from full intensity to nothing', () {
    final paint = Paint();
    final effect = GlowEffect.fadeOut(paint: paint, color: COLOR, controller: .linear(1));
    effect.mount();

    effect.update(0.5);
    expect(paint.colorFilter, ColorFilter.mode(COLOR.withValues(alpha: 0.5), BlendMode.srcIn));

    effect.update(0.5);
    expect(paint.colorFilter, ColorFilter.mode(COLOR.withValues(alpha: 0), BlendMode.srcIn));
  });

  test('scales intensity by the given color\'s own alpha', () {
    final paint = Paint();
    final effect = GlowEffect.fadeIn(
      paint: paint,
      color: COLOR.withValues(alpha: 0.5),
      controller: .linear(1),
    );

    effect.mount();
    effect.update(1);
    expect(paint.colorFilter, ColorFilter.mode(COLOR.withValues(alpha: 0.5), BlendMode.srcIn));
  });

  test('captures the paint\'s existing color filter on mount, and restores it on unmount', () {
    final sentinel = ColorFilter.mode(const Color(0xFF00FF00), BlendMode.multiply);
    final paint = Paint()..colorFilter = sentinel;

    final a = Node();
    final effect = GlowEffect.fadeIn(paint: paint, color: COLOR, controller: .linear(1));
    a.add(effect);
    final scene = a.mount();

    scene.update(0.5);
    expect(paint.colorFilter, isNot(sentinel));

    effect.detach();
    scene.update(0);

    expect(paint.colorFilter, sentinel);
  });

  test('restores a null color filter, if there was none to begin with', () {
    final paint = Paint();

    final a = Node();
    final effect = GlowEffect.fadeIn(paint: paint, color: COLOR, controller: .linear(1));
    a.add(effect);
    final scene = a.mount();

    scene.update(0.5);
    expect(paint.colorFilter, isNotNull);

    effect.detach();
    scene.update(0);

    expect(paint.colorFilter, isNull);
  });
}
