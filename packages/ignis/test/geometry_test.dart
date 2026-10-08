import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  group('pointAt', () {
    test('names a point inside its own box', () {
      final shape = ShapeComponent(shape: .rectangle(.new(40, 20)));

      expect(shape.pointAt(.topLeft), Vector2.zero);
      expect(shape.pointAt(.center), Vector2(20, 10));
      expect(shape.pointAt(.bottomRight), Vector2(40, 20));
    });

    test('ignores its own anchor, which the transform already carries', () {
      final shape = ShapeComponent(
        shape: .square(40),
        anchor: .center,
      );

      expect(shape.pointAt(.center), Vector2.all(20));
    });

    test('center is the middle of the box', () {
      final shape = ShapeComponent(shape: .rectangle(.new(40, 20)));

      expect(shape.center, Vector2(20, 10));
    });
  });

  test('its anchor sits on its position', () {
    final shape = ShapeComponent(
      shape: .square(40),
      position: .all(100),
      anchor: .center,
    );

    expect(Vector2.all(20).transformed(shape.localTransform), Vector2.all(100));
  });
}
