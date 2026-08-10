import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('never finishes', () {
    final controller = InfiniteEffectController(.linear(1));

    expect(controller.duration, double.infinity);
    expect(controller.isInfinite, isTrue);

    controller.advance(100);
    expect(controller.isFinished, isFalse);
  });

  test('loops its child, wrapping progress around', () {
    final controller = InfiniteEffectController(.linear(1));

    expect(controller.advance(2.25), 0);
    expect(controller.progress, 0.25);
  });

  test('recedes backward, wrapping progress around', () {
    final controller = InfiniteEffectController(.linear(1));
    controller.advance(2.25);

    expect(controller.recede(0.5), 0);
    expect(controller.progress, closeTo(0.75, 1e-9));
  });
}
