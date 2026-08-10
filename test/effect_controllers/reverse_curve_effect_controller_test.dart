import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('asserts its duration is positive', () {
    expect(() => ReverseCurveEffectController(0, curve: Curves.linear), throwsAssertionError);
  });

  test('applies its curve counting down', () {
    final controller = ReverseCurveEffectController(1, curve: Curves.easeIn);

    controller.advance(0.5);

    expect(controller.progress, Curves.easeIn.transform(0.5));
    expect(controller.progress, isNot(Curves.easeIn.transform(1)));
  });

  test('reaches zero at the end', () {
    final controller = ReverseCurveEffectController(1, curve: Curves.easeIn);

    controller.advance(1);

    expect(controller.progress, Curves.easeIn.transform(0));
  });
}
