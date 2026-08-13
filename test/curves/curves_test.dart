import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  group('NoiseCurve', () {
    test('stays within -1 and 1', () {
      final curve = NoiseCurve(40, random: math.Random(1));

      for (var i = 0; i <= 100; i += 1) {
        expect(curve.transform(i / 100), inInclusiveRange(-1, 1));
      }
    });

    test('is deterministic for a given seed', () {
      final a = NoiseCurve(40, random: math.Random(42));
      final b = NoiseCurve(40, random: math.Random(42));

      for (var i = 0; i <= 100; i += 1) {
        expect(a.transform(i / 100), b.transform(i / 100));
      }
    });

    test('asserts its sample count is positive', () {
      expect(() => NoiseCurve(0), throwsAssertionError);
    });
  });

  group('SineCurve', () {
    test('oscillates as a sine wave between -1 and 1 over the unit interval', () {
      const curve = SineCurve();

      expect(curve.transform(0), closeTo(0, 1e-9));
      expect(curve.transform(0.25), closeTo(1, 1e-9));
      expect(curve.transform(0.5), closeTo(0, 1e-9));
      expect(curve.transform(0.75), closeTo(-1, 1e-9));
      expect(curve.transform(1), closeTo(0, 1e-9));
    });

    test('matches math.sin(2 * pi * t) directly', () {
      const curve = SineCurve();

      expect(curve.transform(0.1), math.sin(2 * math.pi * 0.1));
    });
  });

  group('ZigzagCurve', () {
    test('oscillates as a triangle wave between -1 and 1 over the unit interval', () {
      const curve = ZigzagCurve();

      expect(curve.transform(0), 0);
      expect(curve.transform(0.25), 1);
      expect(curve.transform(0.5), 0);
      expect(curve.transform(0.75), -1);
      expect(curve.transform(1), 0);
    });
  });
}
