import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('applies its curve', () {
    final controller = DurationEffectController(1, Curves.easeIn);

    controller.advance(0.5);

    expect(controller.progress, Curves.easeIn.transform(0.5));
  });

  test('asserts its duration is positive', () {
    expect(() => DurationEffectController(0), throwsAssertionError);
  });
}
