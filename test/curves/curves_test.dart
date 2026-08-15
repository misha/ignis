import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
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
