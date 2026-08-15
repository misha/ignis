import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('repeats its child, carrying overflow into the next lap', () {
    final controller = RepeatEffectController(.duration(1), 2);

    expect(controller.advance(1.25), 0);
    expect(controller.progress, 0.25);
    expect(controller.isFinished, isFalse);

    expect(controller.advance(0.75), 0);
    expect(controller.progress, 1);
    expect(controller.isFinished, isTrue);
  });

  test(
    'the lap transition needs a following nonzero advance once landed exactly on the boundary',
    () {
      final controller = RepeatEffectController(.duration(1), 2);

      expect(controller.advance(1), 0);
      expect(controller.progress, 1);
      expect(controller.isFinished, isFalse);

      expect(controller.advance(0.5), 0);
      expect(controller.progress, 0.5);
    },
  );

  test('finishes exactly once the last lap lands on the boundary', () {
    final controller = RepeatEffectController(.duration(1), 2);

    controller.advance(1.5);
    expect(controller.advance(0.5), 0);

    expect(controller.isFinished, isTrue);
    expect(controller.progress, 1);
  });

  test('recedes back into a previous lap', () {
    final controller = RepeatEffectController(.duration(1), 2);
    controller.advance(1.5);

    expect(controller.recede(1), 0);
    expect(controller.progress, 0.5);
  });

  test('setToStart() and setToEnd() reset the repeat count', () {
    final controller = RepeatEffectController(.duration(1), 2);

    controller.setToEnd();
    expect(controller.isFinished, isTrue);

    controller.setToStart();
    expect(controller.isFinished, isFalse);
    expect(controller.progress, 0);
  });

  test('asserts times is positive and its child is not infinite', () {
    expect(() => RepeatEffectController(.duration(1), 0), throwsAssertionError);
    expect(
      () => RepeatEffectController(InfiniteEffectController(.duration(1)), 2),
      throwsAssertionError,
    );
  });
}
