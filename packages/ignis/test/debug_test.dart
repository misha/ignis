import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  late Debug debug;

  setUp(() => debug = Debug());

  test('every wireframe draws under itself alone', () {
    for (final wireframe in DebugMode.values) {
      debug.mode = wireframe;

      expect(debug.draws(wireframe), isTrue, reason: '$wireframe draws itself');
    }
  });

  test('toggle puts a wireframe in, and takes it back out', () {
    debug.toggle(.spatial);

    expect(debug.draws(.spatial), isTrue);

    debug.toggle(.spatial);

    expect(debug.draws(.spatial), isFalse);
    expect(debug.enabled, isFalse);
  });

  test('takes a wireframe set outright', () {
    expect(debug.enabled, isFalse);

    debug.mode = .spatial;

    expect(debug.enabled, isTrue);
    expect(debug.draws(.spatial), isTrue);
  });
}
