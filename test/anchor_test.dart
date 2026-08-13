import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  group('named presets', () {
    test('produce the expected fractions', () {
      expect((Anchor.topLeft().x, Anchor.topLeft().y), (0.0, 0.0));
      expect((Anchor.topCenter().x, Anchor.topCenter().y), (0.5, 0.0));
      expect((Anchor.topRight().x, Anchor.topRight().y), (1.0, 0.0));
      expect((Anchor.centerLeft().x, Anchor.centerLeft().y), (0.0, 0.5));
      expect((Anchor.center().x, Anchor.center().y), (0.5, 0.5));
      expect((Anchor.centerRight().x, Anchor.centerRight().y), (1.0, 0.5));
      expect((Anchor.bottomLeft().x, Anchor.bottomLeft().y), (0.0, 1.0));
      expect((Anchor.bottomCenter().x, Anchor.bottomCenter().y), (0.5, 1.0));
      expect((Anchor.bottomRight().x, Anchor.bottomRight().y), (1.0, 1.0));
    });

    test('return a new instance every call', () {
      expect(identical(Anchor.topLeft(), Anchor.topLeft()), isFalse);
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
      expect(Anchor.topLeft().opposite, Anchor.bottomRight());
      expect(Anchor.center().opposite, Anchor.center());
      expect(Anchor(0.25, 0.75).opposite, Anchor(0.75, 0.25));
    });
  });

  group('toOtherAnchorPosition', () {
    test('returns the same position when the anchors are equal', () {
      final position = Vector2(10, 20);
      final result = Anchor.center().toOtherAnchorPosition(
        position,
        .center(),
        .all(100),
      );

      expect(identical(result, position), isTrue);
    });

    test('shifts the position by the anchor delta scaled by the size', () {
      final result = Anchor.topLeft().toOtherAnchorPosition(
        .new(10, 20),
        .bottomRight(),
        .new(100, 50),
      );

      expect(result, Vector2(110, 70));
    });

    test('writes into the given output vector, if provided', () {
      final out = Vector2.zero().mutate();
      final result = Anchor.topLeft().toOtherAnchorPosition(
        .new(10, 20),
        .center(),
        .new(100, 50),
        out,
      );

      expect(identical(result, out.source), isTrue);
      expect(result, Vector2(60, 45));
    });
  });
}
