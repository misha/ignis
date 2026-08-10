import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('is not started until the delay elapses', () {
    final controller = DelayEffectController(0.5);

    expect(controller.hasStarted, isFalse);

    controller.advance(0.25);
    expect(controller.hasStarted, isFalse);

    expect(controller.advance(0.75), 0.5);
    expect(controller.hasStarted, isTrue);
  });

  test('holds progress at zero throughout', () {
    final controller = DelayEffectController(0.5);

    expect(controller.progress, 0);

    controller.advance(0.5);
    expect(controller.progress, 0);
  });

  test('un-starts when receding back below the delay', () {
    final controller = DelayEffectController(0.5);

    controller.advance(0.5);
    expect(controller.hasStarted, isTrue);

    controller.recede(0.1);
    expect(controller.hasStarted, isFalse);
  });
}
