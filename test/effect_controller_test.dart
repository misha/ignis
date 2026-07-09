import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  late EffectController controller;

  setUp(() {
    controller = .new(duration: 1);
  });

  test('advances from zero to one', () {
    expect(controller.hasStarted, isTrue);
    expect(controller.isFinished, isFalse);
    expect(controller.progress, 0);

    expect(controller.advance(0.25), 0);
    expect(controller.progress, 0.25);

    expect(controller.advance(1), 0.25);
    expect(controller.progress, 1);
    expect(controller.isFinished, isTrue);
  });

  test('applies its curve', () {
    controller = .new(
      duration: 1,
      curve: Curves.easeIn,
    );

    controller.advance(0.5);

    expect(controller.progress, Curves.easeIn.transform(0.5));
  });

  test('waits for its start delay', () {
    controller = .new(
      duration: 1,
      startDelay: 0.5,
    );

    controller.advance(0.25);
    expect(controller.hasStarted, isFalse);
    expect(controller.progress, 0);

    controller.advance(0.5);
    expect(controller.hasStarted, isTrue);
    expect(controller.progress, 0.25);
  });

  test('can return to either endpoint', () {
    controller = .new(
      duration: 1,
      startDelay: 0.5,
    );

    controller.setToEnd();
    expect(controller.isFinished, isTrue);
    expect(controller.progress, 1);

    controller.setToStart();
    expect(controller.hasStarted, isFalse);
    expect(controller.isFinished, isFalse);
    expect(controller.progress, 0);
  });

  test('can recede', () {
    controller.setToEnd();

    expect(controller.recede(0.25), 0);
    expect(controller.progress, 0.75);

    expect(controller.recede(1), 0.25);
    expect(controller.progress, 0);
  });
}
