import 'package:flutter/animation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('advances forward, then back down to the start', () {
    final controller = RoundtripEffectController(CurveEffectController(1, Curves.linear));

    expect(controller.duration, 2);

    expect(controller.advance(0.5), 0);
    expect(controller.progress, 0.5);
    expect(controller.isFinished, isFalse);

    expect(controller.advance(0.5), 0);
    expect(controller.progress, 1);
    expect(controller.isFinished, isFalse);

    expect(controller.advance(0.5), 0);
    expect(controller.progress, 0.5);
    expect(controller.isFinished, isFalse);

    expect(controller.advance(0.5), 0);
    expect(controller.progress, 0);
    expect(controller.isFinished, isTrue);
  });

  test('cascades overflow across the leg boundary and past the very end', () {
    final controller = RoundtripEffectController(CurveEffectController(1, Curves.linear));

    expect(controller.advance(1.5), 0);
    expect(controller.progress, 0.5);
    expect(controller.isFinished, isFalse);

    expect(controller.advance(1.5), 1);
    expect(controller.progress, 0);
    expect(controller.isFinished, isTrue);
  });

  test('recedes back through both legs symmetrically', () {
    final controller = RoundtripEffectController(CurveEffectController(1, Curves.linear));
    controller.advance(2);
    expect(controller.isFinished, isTrue);

    expect(controller.recede(0.5), 0);
    expect(controller.progress, 0.5);
    expect(controller.isFinished, isFalse);

    expect(controller.recede(1), 0);
    expect(controller.progress, 0.5);

    expect(controller.recede(0.5), 0);
    expect(controller.progress, 0);
  });

  test('setToStart() and setToEnd() reset the child and both legs', () {
    final controller = RoundtripEffectController(CurveEffectController(1, Curves.linear));

    controller.setToEnd();
    expect(controller.isFinished, isTrue);
    expect(controller.progress, 0);

    controller.setToStart();
    expect(controller.isFinished, isFalse);
    expect(controller.progress, 0);
  });
}
