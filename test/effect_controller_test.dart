import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  group('EffectController', () {
    late EffectController controller;

    setUp(() {
      controller = EffectController(duration: 1);
    });

    test('advances from zero to one', () {
      expect(controller.hasStarted, isTrue);
      expect(controller.isFinished, isFalse);
      expect(controller.progress, 0);

      controller.update(0.25);
      expect(controller.progress, 0.25);

      controller.update(1);
      expect(controller.progress, 1);
      expect(controller.isFinished, isTrue);
    });

    test('applies its curve', () {
      controller = EffectController(duration: 1, curve: Curves.easeIn);

      controller.update(0.5);

      expect(controller.progress, Curves.easeIn.transform(0.5));
    });

    test('waits for its start delay', () {
      controller = EffectController(duration: 1, startDelay: 0.5);

      controller.update(0.25);
      expect(controller.hasStarted, isFalse);
      expect(controller.progress, 0);

      controller.update(0.5);
      expect(controller.hasStarted, isTrue);
      expect(controller.progress, 0.25);
    });

    test('reset() returns to the start', () {
      controller = EffectController(duration: 1, startDelay: 0.5);

      controller.update(1);
      expect(controller.hasStarted, isTrue);

      controller.reset();
      expect(controller.hasStarted, isFalse);
      expect(controller.isFinished, isFalse);
      expect(controller.progress, 0);
    });

    test('can repeat, carrying over any overflow', () {
      controller = EffectController(duration: 1, times: 2);

      final result = controller.update(1.25);
      expect(result.repeat, isTrue); // First repeat is done, second begins.
      expect(controller.progress, 0.25); // Overflow carried into the new repeat.
      expect(controller.isFinished, isFalse);
      expect(controller.canRepeat, isFalse); // No repeats remain after this one.

      controller.update(0.75);
      expect(controller.isFinished, isTrue);
    });

    test('repeats forever when times is null', () {
      controller = EffectController(duration: 1, times: null);

      for (var i = 0; i < 5; i += 1) {
        final result = controller.update(1);
        expect(result.repeat, isTrue);
        expect(controller.canRepeat, isTrue);
      }
    });

    test('reset() resets the repeat count', () {
      controller = EffectController(duration: 1, times: 2);
      controller.update(1); // Uses up the only repeat.
      expect(controller.canRepeat, isFalse);

      controller.reset();

      expect(controller.canRepeat, isTrue);
    });

    test('defaults reverseDuration and reverseCurve to duration and curve', () {
      controller = EffectController(duration: 1, curve: Curves.easeIn, reverse: true);

      expect(controller.reverseDuration, 1);
      expect(controller.reverseCurve, Curves.easeIn);
    });

    test('reverses back to the start after reaching the end', () {
      controller = EffectController(duration: 1, reverse: true);

      controller.update(1);
      expect(controller.progress, 1);
      expect(controller.isFinished, isFalse); // Only the forward phase is done.

      controller.update(0.5);
      expect(controller.progress, 0.5);
      expect(controller.isFinished, isFalse);

      controller.update(0.5);
      expect(controller.progress, 0);
      expect(controller.isFinished, isTrue);
    });

    test('carries overflow from the forward phase into the reverse phase', () {
      controller = EffectController(duration: 1, reverse: true);

      controller.update(1.25);
      expect(controller.progress, 0.75); // 0.25 into the reverse phase.
      expect(controller.isFinished, isFalse);
    });

    test('applies reverseDuration and reverseCurve independently', () {
      controller = EffectController(
        duration: 1,
        reverse: true,
        reverseDuration: 2,
        reverseCurve: Curves.easeIn,
      );

      controller.update(1); // Finishes the forward phase.
      controller.update(1); // Halfway through the (longer) reverse phase.

      expect(controller.progress, 1 - Curves.easeIn.transform(0.5));
    });

    test('pauses at the end for reverseDelay before the reverse phase starts', () {
      controller = EffectController(duration: 1, reverse: true, reverseDelay: 0.5);

      controller.update(1); // Finishes the forward phase.
      expect(controller.progress, 1);
      expect(controller.isFinished, isFalse);

      controller.update(0.5); // Waits out the reverse delay.
      expect(controller.progress, 1);
      expect(controller.isFinished, isFalse);

      controller.update(1);
      expect(controller.progress, 0);
      expect(controller.isFinished, isTrue);
    });

    test('automatically restarts from the forward phase on repeat', () {
      controller = EffectController(duration: 1, reverse: true, times: 2);

      controller.update(1);
      final result = controller.update(1); // Completes the reverse phase too.
      expect(result.repeat, isTrue);
      expect(controller.progress, 0);

      controller.update(1);
      expect(controller.progress, 1); // Back in the forward phase.
    });
  });

  group('ManualEffectController', () {
    late ManualEffectController controller;

    setUp(() {
      controller = ManualEffectController(duration: 1);
    });

    test('sits at rest until played', () {
      expect(controller.hasStarted, isTrue);
      expect(controller.position, 0);
      expect(controller.progress, 0);

      final result = controller.update(0.5);

      expect(
        result,
        EffectControllerResult(
          progress: 0.0,
          repeat: false,
          finish: false,
          reset: false,
        ),
      );

      expect(controller.position, 0); // Nothing to play toward yet.
    });

    test('seek() jumps directly to a position', () {
      controller.seek(0.5);
      expect(controller.position, 0.5);
      expect(controller.progress, 0.5);
    });

    test('play() steps toward its target over successive ticks', () {
      controller.play(to: 1);

      expect(
        controller.update(0.25),
        EffectControllerResult(
          progress: 0.25,
          repeat: false,
          finish: false,
          reset: false,
        ),
      );

      expect(
        controller.update(0.75),
        EffectControllerResult(
          progress: 1.0,
          repeat: false,
          finish: true,
          reset: false,
        ),
      );
    });

    test('play(to: 0) plays backward from wherever it currently is', () {
      controller.seek(0.75);
      controller.play(to: 0);

      expect(
        controller.update(0.25),
        EffectControllerResult(
          progress: 0.5,
          repeat: false,
          finish: false,
          reset: true,
        ),
      );

      expect(
        controller.update(0.5),
        EffectControllerResult(
          progress: 0.0,
          repeat: false,
          finish: true,
          reset: true,
        ),
      );
    });

    test('play() supports any sub-range, e.g. two-thirds of the way back from the end', () {
      controller.play(from: 1, to: 1 / 3);

      final result = controller.update(1 / 3);

      expect(result.progress, closeTo(2 / 3, 1e-9));
      expect(result.finish, isFalse);
    });

    test('redirecting mid-flight resumes from the current point, with no jump', () {
      controller.play(to: 1);
      controller.update(0.4);
      final before = controller.position;

      controller.play(to: 0);

      expect(controller.position, before); // Redirected, not reset.
    });

    test('reports finished every tick once resting at the target', () {
      controller.play(to: 1);
      controller.update(1);

      expect(
        controller.update(0.1),
        EffectControllerResult(
          progress: 1.0,
          repeat: false,
          finish: true,
          reset: false,
        ),
      );

      expect(controller.position, 1); // Doesn't overshoot from ticking again.
    });

    test('applies reverseCurve only while playing toward a lower position', () {
      controller = ManualEffectController(
        duration: 1,
        curve: Curves.linear,
        reverseCurve: Curves.easeIn,
      );

      controller.seek(1);
      controller.play(to: 0);
      controller.update(0.5);

      expect(controller.progress, Curves.easeIn.transform(0.5));
    });

    test('reset() returns to position 0 with nothing to play toward', () {
      controller.play(to: 1);
      controller.update(0.5);
      controller.reset();

      expect(controller.position, 0);
      expect(
        controller.update(0.5),
        EffectControllerResult(
          progress: 0.0,
          repeat: false,
          finish: false,
          reset: false,
        ),
      );
    });
  });
}
