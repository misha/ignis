import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('is not started until its child finishes', () {
    final controller = OnceEffectController(WaitEffectController(0.5));

    expect(controller.hasStarted, isFalse);

    controller.advance(0.25);
    expect(controller.hasStarted, isFalse);

    expect(controller.advance(0.75), 0.5);
    expect(controller.hasStarted, isTrue);
  });

  test('advancing past its child finishing still returns the leftover time', () {
    final controller = OnceEffectController(WaitEffectController(0.5));

    expect(controller.advance(0.5), 0);
    expect(controller.advance(0.5), 0.5);
  });

  test('ignores recede once finished, leaving its child untouched', () {
    final controller = OnceEffectController(WaitEffectController(0.5));
    controller.advance(0.5);

    expect(controller.recede(0.5), 0.5);
    expect(controller.isFinished, isTrue);
    expect(controller.child.isFinished, isTrue);
  });

  test('ignores setToStart() once finished, so a repeat never redoes it', () {
    final controller = OnceEffectController(WaitEffectController(0.5));
    controller.advance(0.5);

    controller.setToStart();

    expect(controller.isFinished, isTrue);
    expect(controller.progress, 1);
  });

  test('setToStart() before finishing resets its child normally', () {
    final controller = OnceEffectController(DurationEffectController(1));
    controller.advance(0.5);

    controller.setToStart();

    expect(controller.progress, 0);
    expect(controller.isFinished, isFalse);
  });

  test('setToEnd() delegates to its child and finishes', () {
    final controller = OnceEffectController(DurationEffectController(1));

    controller.setToEnd();

    expect(controller.progress, 1);
    expect(controller.isFinished, isTrue);
  });

  test('delegates duration and progress to its child', () {
    final controller = OnceEffectController(WaitEffectController(0.5));

    expect(controller.duration, 0.5);
    expect(controller.progress, 1);
  });
}
