import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('oscillates as a sine wave between -1 and 1', () {
    final controller = SineEffectController(period: 4);

    expect(controller.progress, closeTo(0, 1e-9));

    controller.advance(1);
    expect(controller.progress, closeTo(1, 1e-9));

    controller.advance(1);
    expect(controller.progress, closeTo(0, 1e-9));

    controller.advance(1);
    expect(controller.progress, closeTo(-1, 1e-9));

    controller.advance(1);
    expect(controller.progress, closeTo(0, 1e-9));
  });

  test('matches math.sin directly', () {
    final controller = SineEffectController(period: 2 * math.pi);

    controller.advance(1);

    expect(controller.progress, math.sin(1));
  });

  test('asserts its period is positive', () {
    expect(() => SineEffectController(period: 0), throwsAssertionError);
  });
}
