import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('advances through children in order, cascading overflow', () {
    final controller = SequenceEffectController([
      .linear(1),
      .linear(1),
    ]);

    expect(controller.advance(1.5), 0);
    expect(controller.progress, 0.5);
    expect(controller.isFinished, isFalse);

    expect(controller.advance(0.5), 0);
    expect(controller.progress, 1);
    expect(controller.isFinished, isTrue);
  });

  test('delegates progress and hasStarted to the current child', () {
    final controller = SequenceEffectController([
      .delay(0.5),
      .linear(1),
    ]);

    expect(controller.hasStarted, isFalse);
    expect(controller.progress, 0);

    controller.advance(0.5);
    expect(controller.hasStarted, isTrue);

    controller.advance(0.25);
    expect(controller.progress, 0.25);
  });

  test('recedes back through children in reverse order', () {
    final controller = SequenceEffectController([
      .linear(1),
      .linear(1),
    ]);

    controller.advance(1.5);

    expect(controller.recede(1), 0);
    expect(controller.progress, 0.5);

    expect(controller.recede(0.5), 0);
    expect(controller.progress, 0);
  });

  test('setToStart() and setToEnd() reset every child', () {
    final controller = SequenceEffectController([
      .linear(1),
      .linear(1),
    ]);

    controller.setToEnd();
    expect(controller.isFinished, isTrue);
    expect(controller.progress, 1);

    controller.setToStart();
    expect(controller.isFinished, isFalse);
    expect(controller.progress, 0);

    controller.advance(1.5);
    controller.setToStart();
    expect(controller.progress, 0);
  });

  test('asserts at least 1 child is given', () {
    expect(() => SequenceEffectController([]), throwsAssertionError);
  });
}
