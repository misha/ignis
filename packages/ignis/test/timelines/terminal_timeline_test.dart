import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('is always already finished, at progress 1', () {
    final timeline = TerminalTimeline();

    expect(timeline.duration, 0);
    expect(timeline.hasStarted, isTrue);
    expect(timeline.isFinished, isTrue);
    expect(timeline.progress, 1);
  });

  test('advance() and recede() consume no time, returning it all as overflow', () {
    final timeline = TerminalTimeline();

    expect(timeline.advance(1), 1);
    expect(timeline.recede(1), 1);
    expect(timeline.progress, 1);
    expect(timeline.isFinished, isTrue);
  });

  test('setToStart() and setToEnd() are no-ops', () {
    final timeline = TerminalTimeline();

    timeline.setToStart();
    expect(timeline.progress, 1);

    timeline.setToEnd();
    expect(timeline.progress, 1);
  });
}
