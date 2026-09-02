import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('waits at zero progress', () {
    const snapshot = PreloadSnapshot.waiting();
    expect(snapshot.progress, 0);
    expect(snapshot.done, isFalse);
    expect(snapshot.hasError, isFalse);
  });

  test('reports zero progress while the total is unknown', () {
    const snapshot = PreloadSnapshot(total: 0, completed: 0, accepted: 0, done: false);
    expect(snapshot.progress, 0);
  });

  test('reports the completed fraction while running', () {
    const snapshot = PreloadSnapshot(total: 4, completed: 1, accepted: 1, done: false);
    expect(snapshot.progress, 0.25);
  });

  test('reports full progress once done, a failure included', () {
    final snapshot = const PreloadSnapshot.waiting().copyWith(
      done: true,
      error: StateError('load failed'),
    );

    expect(snapshot.progress, 1);
    expect(snapshot.hasError, isTrue);
  });

  test('succeeds only once done cleanly', () {
    const waiting = PreloadSnapshot.waiting();
    expect(waiting.succeeded, isFalse);
    expect(waiting.copyWith(done: true).succeeded, isTrue);
    expect(waiting.copyWith(done: true, error: StateError('load failed')).succeeded, isFalse);
    expect(waiting.copyWith(done: true, cancelled: true).succeeded, isFalse);
  });
}
