import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  late Debug debug;

  setUp(() => debug = Debug());

  test('draws its own wireframe and no other', () {
    debug.mode = .collision;

    expect(debug.draws(.collision), isTrue);
    expect(debug.draws(.spatial), isFalse);
    expect(debug.draws(.input), isFalse);
    expect(debug.draws(.layout), isFalse);
  });

  test('every wireframe draws under itself alone', () {
    for (final wireframe in DebugMode.values) {
      debug.mode = wireframe;

      expect(debug.draws(wireframe), isTrue, reason: '$wireframe draws itself');
    }
  });

  test('a second wireframe replaces the first, rather than joining it', () {
    debug.mode = .spatial;
    debug.mode = .input;

    expect(debug.draws(.input), isTrue);
    expect(debug.draws(.spatial), isFalse);
  });

  test('toggle puts a wireframe in, and takes it back out', () {
    debug.toggle(.collision);

    expect(debug.draws(.collision), isTrue);

    debug.toggle(.collision);

    expect(debug.draws(.collision), isFalse);
    expect(debug.enabled, isFalse);
  });

  test('toggle moves to another wireframe, rather than clearing', () {
    debug.mode = .spatial;

    debug.toggle(.input);

    expect(debug.draws(.input), isTrue);
    expect(debug.enabled, isTrue);
  });

  test('takes a wireframe set outright', () {
    expect(debug.enabled, isFalse);

    debug.mode = .layout;

    expect(debug.enabled, isTrue);
    expect(debug.draws(.layout), isTrue);
  });
}
