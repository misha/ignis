import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  group('named presets', () {
    test('produce the expected fractions', () {
      expect((Anchor.topLeft.x, Anchor.topLeft.y), (0.0, 0.0));
      expect((Anchor.topCenter.x, Anchor.topCenter.y), (0.5, 0.0));
      expect((Anchor.topRight.x, Anchor.topRight.y), (1.0, 0.0));
      expect((Anchor.centerLeft.x, Anchor.centerLeft.y), (0.0, 0.5));
      expect((Anchor.center.x, Anchor.center.y), (0.5, 0.5));
      expect((Anchor.centerRight.x, Anchor.centerRight.y), (1.0, 0.5));
      expect((Anchor.bottomLeft.x, Anchor.bottomLeft.y), (0.0, 1.0));
      expect((Anchor.bottomCenter.x, Anchor.bottomCenter.y), (0.5, 1.0));
      expect((Anchor.bottomRight.x, Anchor.bottomRight.y), (1.0, 1.0));
    });

    test('return the same canonical instance every call', () {
      expect(identical(Anchor.topLeft, Anchor.topLeft), isTrue);
    });
  });

  group('equality', () {
    test('anchors with the same fractions are equal', () {
      expect(Anchor(0.5, 0.25), Anchor(0.5, 0.25));
      expect(Anchor(0.5, 0.25).hashCode, Anchor(0.5, 0.25).hashCode);
    });

    test('anchors with different fractions are not equal', () {
      expect(Anchor(0.5, 0.25), isNot(Anchor(0.25, 0.5)));
    });
  });

  group('opposite', () {
    test('mirrors both fractions around the center', () {
      expect(Anchor.topLeft.opposite, Anchor.bottomRight);
      expect(Anchor.center.opposite, Anchor.center);
      expect(Anchor(0.25, 0.75).opposite, Anchor(0.75, 0.25));
    });
  });
}
