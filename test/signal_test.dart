import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('emits its arguments', () {
    for (final signal in _signals()) {
      final seen = <Object?>[];
      watch(signal, seen);
      emit(signal, 1);
      expect(seen, [emission(signal, 1)]);
    }
  });

  test('listeners added during emission run on the next emission', () {
    for (final signal in _signals()) {
      final seen = <Object?>[];
      late Cleanup bootstrap;

      bootstrap = signal.watch(() {
        bootstrap();
        watch(signal, seen);
      });

      emit(signal, 1);
      expect(seen, isEmpty);

      emit(signal, 2);
      expect(seen, [emission(signal, 2)]);
    }
  });

  test('listeners removed during emission are skipped for the rest of that emission', () {
    for (final signal in _signals()) {
      final seen1 = <Object?>[];
      final seen2 = <Object?>[];

      late Cleanup unwatch1;
      late Cleanup unwatch2;

      unwatch1 = watch(signal, seen1, () => unwatch2());
      unwatch2 = watch(signal, seen2);

      emit(signal, 1);
      unwatch1();
      emit(signal, 2);

      expect(seen1, [emission(signal, 1)]);
      expect(seen2, isEmpty);
    }
  });

  test('a listener added from within a nested emission sees that emission', () {
    for (final signal in _signals()) {
      final seen = <String>[];
      var reentered = false;

      signal.watch(() {
        seen.add('A');

        if (!reentered) {
          reentered = true;
          signal.watch(() => seen.add('B'));
          emit(signal, 1);
        }
      });

      emit(signal, 1);
      expect(seen, ['A', 'A', 'B']);

      seen.clear();
      emit(signal, 1);
      expect(seen, ['A', 'B']);
    }
  });

  test('listeners can disconnect', () {
    for (final signal in _signals()) {
      final seen = <Object?>[];
      final unwatch = watch(signal, seen);
      emit(signal, 1);
      unwatch();
      emit(signal, 2);

      expect(seen, [emission(signal, 1)]);
    }
  });

  test('listeners remain connected across emissions', () {
    for (final signal in _signals()) {
      final seen = <Object?>[];
      watch(signal, seen);
      emit(signal, 1);
      emit(signal, 1);

      expect(seen, [emission(signal, 1), emission(signal, 1)]);
    }
  });

  test('multiple listeners see the same emission', () {
    for (final signal in _signals()) {
      final seen1 = <Object?>[];
      final seen2 = <Object?>[];
      watch(signal, seen1);
      watch(signal, seen2);
      emit(signal, 1);

      expect(seen1, [emission(signal, 1)]);
      expect(seen2, [emission(signal, 1)]);
    }
  });
}

List<Signal> _signals() {
  return [
    Signal0(),
    Signal1<int>(),
    Signal2<int, int>(),
    Signal3<int, int, int>(),
  ];
}

Cleanup watch(Signal signal, List<Object?> sink, [void Function()? then]) {
  switch (signal) {
    case Signal0():
      return signal(() {
        sink.add(null);
        then?.call();
      });

    case Signal1():
      return signal((a) {
        sink.add(a);
        then?.call();
      });

    case Signal2():
      return signal((a, b) {
        sink.add((a, b));
        then?.call();
      });

    case Signal3():
      return signal((a, b, c) {
        sink.add((a, b, c));
        then?.call();
      });
  }
}

void emit(Signal signal, int n) {
  switch (signal) {
    case Signal0():
      signal.emit();

    case Signal1():
      signal.emit(n);

    case Signal2():
      signal.emit(n, n + 1);

    case Signal3():
      signal.emit(n, n + 1, n + 2);
  }
}

dynamic emission(Signal signal, int n) {
  return switch (signal) {
    Signal0() => null,
    Signal1() => n,
    Signal2() => (n, n + 1),
    Signal3() => (n, n + 1, n + 2),
  };
}
