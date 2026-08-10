import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('oscillates as a triangle wave between -1 and 1', () {
    final controller = ZigzagEffectController(period: 4);

    expect(controller.progress, 0);

    controller.advance(1);
    expect(controller.progress, 1);

    controller.advance(1);
    expect(controller.progress, 0);

    controller.advance(1);
    expect(controller.progress, -1);

    controller.advance(1);
    expect(controller.progress, 0);
  });

  test('asserts its period is positive', () {
    expect(() => ZigzagEffectController(period: 0), throwsAssertionError);
  });
}
