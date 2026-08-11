import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('applies its curve', () {
    final controller = CurveEffectController(1, Curves.easeIn);

    controller.advance(0.5);

    expect(controller.progress, Curves.easeIn.transform(0.5));
  });

  test('asserts its duration is positive', () {
    expect(() => CurveEffectController(0, Curves.linear), throwsAssertionError);
  });

  test('.linear is a curve using Curves.linear', () {
    final controller = EffectController.linear(1);

    expect(
      controller,
      isA<CurveEffectController>() //
          .having((c) => c.curve, 'curve', Curves.linear),
    );
  });

  test('defaults to running forward, not reversed', () {
    final controller = CurveEffectController(1, Curves.linear);

    expect(controller.reverse, isFalse);
  });

  test('applies its curve counting down, when reverse is true', () {
    final controller = CurveEffectController(1, Curves.easeIn, reverse: true);

    controller.advance(0.5);

    expect(controller.progress, Curves.easeIn.transform(0.5));
    expect(controller.progress, isNot(Curves.easeIn.transform(1)));
  });

  test('reaches zero at the end, when reverse is true', () {
    final controller = CurveEffectController(1, Curves.easeIn, reverse: true);

    controller.advance(1);

    expect(controller.progress, Curves.easeIn.transform(0));
  });
}
