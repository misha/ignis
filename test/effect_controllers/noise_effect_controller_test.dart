import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('stays within -1 and 1', () {
    final controller = NoiseEffectController(4, frequency: 10, random: Random(1));

    for (var i = 0; i < 40; i += 1) {
      controller.advance(0.1);
      expect(controller.progress, inInclusiveRange(-1, 1));
    }
  });

  test('is deterministic for a given seed', () {
    final a = NoiseEffectController(4, frequency: 10, random: Random(42));
    final b = NoiseEffectController(4, frequency: 10, random: Random(42));

    for (var i = 0; i < 40; i += 1) {
      a.advance(0.1);
      b.advance(0.1);
      expect(a.progress, b.progress);
    }
  });

  test('replays the same progress after setToStart()', () {
    final controller = NoiseEffectController(4, frequency: 10, random: Random(7));

    controller.advance(1.5);
    final progress = controller.progress;

    controller.setToStart();
    controller.advance(1.5);

    expect(controller.progress, progress);
  });

  test('asserts its frequency is positive', () {
    expect(() => NoiseEffectController(1, frequency: 0), throwsAssertionError);
  });
}
