import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('is always already finished, at its progress', () {
    final controller = TerminalEffectController(progress: 0.5);

    expect(controller.duration, 0);
    expect(controller.hasStarted, isTrue);
    expect(controller.isFinished, isTrue);
    expect(controller.progress, 0.5);
  });

  test('defaults its progress to one', () {
    final controller = TerminalEffectController();

    expect(controller.progress, 1);
  });

  test('advance() and recede() consume no time, returning it all as overflow', () {
    final controller = TerminalEffectController();

    expect(controller.advance(1), 1);
    expect(controller.recede(1), 1);
    expect(controller.progress, 1);
    expect(controller.isFinished, isTrue);
  });

  test('setToStart() and setToEnd() are no-ops', () {
    final controller = TerminalEffectController(progress: 0.5);

    controller.setToStart();
    expect(controller.progress, 0.5);

    controller.setToEnd();
    expect(controller.progress, 0.5);
  });
}
