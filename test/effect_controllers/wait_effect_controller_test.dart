import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('holds progress at 1 while running', () {
    final controller = WaitEffectController(1);

    expect(controller.progress, 1);

    controller.advance(0.5);
    expect(controller.progress, 1);
    expect(controller.isFinished, isFalse);

    controller.advance(0.5);
    expect(controller.progress, 1);
    expect(controller.isFinished, isTrue);
  });

  test('is always considered started', () {
    final controller = WaitEffectController(1);

    expect(controller.hasStarted, isTrue);
  });

  test('returns overflow once its duration elapses', () {
    final controller = WaitEffectController(1);

    expect(controller.advance(1.5), 0.5);
  });

  test('asserts its duration is positive; use TerminalEffectController for zero', () {
    expect(() => WaitEffectController(0), throwsAssertionError);
  });
}
