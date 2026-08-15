import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  group('PositionOwner.box', () {
    test('defaults to the zero vector', () {
      expect(PositionOwner.box().position, Vector2.zero);
    });

    test('reuses a given MVector2 directly, without cloning', () {
      final position = MVector2(3, 4);
      expect(PositionOwner.box(position).position, same(position));
    });
  });

  group('ScaleOwner.box', () {
    test('defaults to a scale of (1, 1)', () {
      expect(ScaleOwner.box().scale, Vector2.all(1));
    });

    test('reuses a given MVector2 directly, without cloning', () {
      final scale = MVector2(2, 3);
      expect(ScaleOwner.box(scale).scale, same(scale));
    });
  });

  group('AngleOwner.box', () {
    test('defaults to an angle of 0', () {
      expect(AngleOwner.box().angle, 0);
    });

    test('starts at a given angle', () {
      expect(AngleOwner.box(2).angle, 2);
    });
  });

  group('SpeedOwner.box', () {
    test('defaults to a speed of 0', () {
      expect(SpeedOwner.box().speed, 0);
    });

    test('starts at a given speed', () {
      expect(SpeedOwner.box(2).speed, 2);
    });
  });

  group('AnchorOwner.box', () {
    test('defaults to topLeft', () {
      expect(AnchorOwner.box().anchor, Anchor.topLeft);
    });

    test('reuses a given Anchor directly, without cloning', () {
      final anchor = Anchor.center;
      expect(AnchorOwner.box(anchor).anchor, same(anchor));
    });
  });
}
