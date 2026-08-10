import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('holds progress constant while running', () {
    final controller = PauseEffectController(1, progress: 0.5);

    expect(controller.progress, 0.5);

    controller.advance(0.5);
    expect(controller.progress, 0.5);
    expect(controller.isFinished, isFalse);

    controller.advance(0.5);
    expect(controller.progress, 0.5);
    expect(controller.isFinished, isTrue);
  });

  test('defaults its held progress to one', () {
    final controller = PauseEffectController(1);

    expect(controller.progress, 1);
  });

  test('is always considered started', () {
    final controller = PauseEffectController(1);

    expect(controller.hasStarted, isTrue);
  });

  test('returns overflow once its duration elapses', () {
    final controller = PauseEffectController(1);

    expect(controller.advance(1.5), 0.5);
  });
}
