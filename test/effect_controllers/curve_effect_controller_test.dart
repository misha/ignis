import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('applies its curve', () {
    final controller = CurveEffectController(1, curve: Curves.easeIn);

    controller.advance(0.5);

    expect(controller.progress, Curves.easeIn.transform(0.5));
  });

  test('asserts its duration is positive', () {
    expect(() => CurveEffectController(0, curve: Curves.linear), throwsAssertionError);
  });

  test('.linear is a curve using Curves.linear', () {
    final controller = EffectController.linear(1);

    expect(
      controller,
      isA<CurveEffectController>() //
          .having((c) => c.curve, 'curve', Curves.linear),
    );
  });
}
