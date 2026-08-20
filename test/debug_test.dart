import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  late Debug debug;

  setUp(() => debug = Debug());

  test('draws its own wireframe and no other', () {
    debug.mode = .collisions;

    expect(debug.draws(.collisions), isTrue);
    expect(debug.draws(.transforms), isFalse);
    expect(debug.draws(.inputs), isFalse);
    expect(debug.draws(.layouts), isFalse);
  });

  test('all draws every one of them', () {
    debug.mode = .all;

    for (final wireframe in DebugMode.values) {
      expect(debug.draws(wireframe), isTrue, reason: '$wireframe draws under all');
    }
  });

  test('holds two wireframes at once, and no third', () {
    debug.mode = DebugMode.transforms | .inputs;

    expect(debug.draws(.transforms), isTrue);
    expect(debug.draws(.inputs), isTrue);
    expect(debug.draws(.collisions), isFalse);
    expect(debug.draws(.layouts), isFalse);
  });

  test('toggle puts a wireframe in, and takes it back out', () {
    debug.toggle(.collisions);

    expect(debug.draws(.collisions), isTrue);

    debug.toggle(.collisions);

    expect(debug.draws(.collisions), isFalse);
    expect(debug.enabled, isFalse);
  });

  test('toggle leaves every wireframe beside it alone', () {
    debug.mode = .all;

    debug.toggle(.inputs);

    expect(debug.draws(.inputs), isFalse);
    expect(debug.draws(.transforms), isTrue);
    expect(debug.draws(.collisions), isTrue);
    expect(debug.draws(.layouts), isTrue);
  });

  test('is settable outright, with no cycle in sight', () {
    expect(debug.enabled, isFalse);

    debug.mode = .layouts;

    expect(debug.enabled, isTrue);
    expect(debug.draws(.layouts), isTrue);
  });
}
