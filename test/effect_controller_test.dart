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

  test('waits for its initial delay', () {
    controller = .new(
      duration: 1,
      initialDelay: 0.5,
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
      initialDelay: 0.5,
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

  test('can repeat, carrying over any overflow', () {
    controller = .new(duration: 1, times: 2);

    expect(controller.advance(1.25), 0.25);
    expect(controller.isFinished, isTrue); // First repeat is done.
    expect(controller.canRepeat, isTrue); // A second repeat remains.

    controller.repeat(0.25);
    expect(controller.progress, 0.25); // Overflow carried into the new repeat.
    expect(controller.isFinished, isFalse);

    expect(controller.advance(0.75), 0);
    expect(controller.isFinished, isTrue);
    expect(controller.canRepeat, isFalse); // No repeats remain.
  });

  test('repeats forever when times is null', () {
    controller = .new(duration: 1, times: null);

    for (var i = 0; i < 5; i += 1) {
      controller.advance(1);
      expect(controller.canRepeat, isTrue);
      controller.repeat();
    }
  });

  test('setToStart() resets the repeat count', () {
    controller = .new(duration: 1, times: 2);
    controller.advance(1);
    controller.repeat();

    controller.setToStart();

    expect(controller.canRepeat, isTrue);
  });

  test('recede() floors at bottomDelay once started, even within the same lap', () {
    controller = .new(duration: 1, initialDelay: 0.5, bottomDelay: 0.25);

    controller.advance(0.75);
    expect(controller.recede(10), 9.5);
    expect(controller.hasStarted, isFalse);
    expect(controller.progress, 0);
  });

  test('repeat() restarts using bottomDelay, not initialDelay', () {
    controller = .new(duration: 1, times: 2, initialDelay: 0.5, bottomDelay: 0.25);

    controller.advance(1.5);
    controller.repeat();

    expect(controller.hasStarted, isFalse);

    expect(controller.advance(0.25), 0);
    expect(controller.hasStarted, isTrue);
    expect(controller.progress, 0);
  });

  test('recede() floors at initialDelay initially, then at bottomDelay after each repeat', () {
    controller = .new(duration: 1, times: 2, initialDelay: 0.5, bottomDelay: 0.25);

    expect(controller.recede(10), 10);
    expect(controller.progress, 0);

    controller.advance(1.5);
    controller.repeat();

    expect(controller.recede(10), 10);
    expect(controller.progress, 0);
  });

  test('defaults reverseDuration and reverseCurve to duration and curve', () {
    controller = .new(duration: 1, curve: Curves.easeIn, reverse: true);

    expect(controller.reverseDuration, 1);
    expect(controller.reverseCurve, Curves.easeIn);
  });

  test('reverses back to the start after reaching the end', () {
    controller = .new(duration: 1, reverse: true);

    expect(controller.advance(1), 0);
    expect(controller.progress, 1);
    expect(controller.isFinished, isFalse); // Only the forward phase is done.

    expect(controller.advance(0.5), 0);
    expect(controller.progress, 0.5);
    expect(controller.isFinished, isFalse);

    expect(controller.advance(0.5), 0);
    expect(controller.progress, 0);
    expect(controller.isFinished, isTrue);
  });

  test('carries overflow from the forward phase into the reverse phase', () {
    controller = .new(duration: 1, reverse: true);

    expect(controller.advance(1.25), 0);
    expect(controller.progress, 0.75); // 0.25 into the reverse phase.
    expect(controller.isFinished, isFalse);
  });

  test('applies reverseDuration and reverseCurve independently', () {
    controller = .new(
      duration: 1,
      reverse: true,
      reverseDuration: 2,
      reverseCurve: Curves.easeIn,
    );

    controller.advance(1); // Finishes the forward phase.
    controller.advance(1); // Halfway through the (longer) reverse phase.

    expect(controller.progress, 1 - Curves.easeIn.transform(0.5));
  });

  test('pauses at the end for topDelay before the reverse phase starts', () {
    controller = .new(duration: 1, reverse: true, topDelay: 0.5);

    expect(controller.advance(1), 0); // Finishes the forward phase.
    expect(controller.progress, 1);
    expect(controller.isFinished, isFalse);

    expect(controller.advance(0.5), 0); // Waits out the reverse delay.
    expect(controller.progress, 1);
    expect(controller.isFinished, isFalse);

    expect(controller.advance(1), 0);
    expect(controller.progress, 0);
    expect(controller.isFinished, isTrue);
  });

  test('setToEnd() parks at the end of the reverse phase, when reverse is true', () {
    controller = .new(duration: 1, reverse: true, reverseDuration: 2);

    controller.setToEnd();

    expect(controller.isFinished, isTrue);
    expect(controller.progress, 0);
  });

  test('repeat() restarts from the forward phase', () {
    controller = .new(duration: 1, reverse: true, times: 2);

    controller.advance(1);
    controller.advance(1); // Completes the reverse phase too.
    expect(controller.isFinished, isTrue);

    controller.repeat();
    expect(controller.progress, 0);

    controller.advance(1);
    expect(controller.progress, 1); // Back in the forward phase.
  });
}
