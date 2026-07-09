import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  late Cache cache;

  setUp(() {
    cache = Cache();
  });

  test('adds and retrieves typed values', () {
    cache
      ..add('number', 42)
      ..add('label', 'answer');

    expect(cache.length, 2);
    expect(cache.keys, containsAll(['number', 'label']));
    expect(cache.contains('number'), isTrue);
    expect(cache.retrieve<int>('number'), 42);
    expect(cache.retrieve<String>('label'), 'answer');
  });

  test('replaces an existing value', () {
    cache
      ..add('value', 1)
      ..add('value', 2);

    expect(cache.length, 1);
    expect(cache.retrieve<int>('value'), 2);
  });

  test('rejects missing keys', () {
    expect(
      () => cache.retrieve<Object>('missing'),
      throwsA(isA<StateError>()),
    );
  });

  test('rejects values of the wrong type', () {
    cache.add('value', 42);

    expect(
      () => cache.retrieve<String>('value'),
      throwsA(isA<StateError>()),
    );
  });

  test('evicts individual values', () {
    cache.add('value', 42);

    expect(cache.evict('value'), isTrue);
    expect(cache.evict('value'), isFalse);
    expect(cache.contains('value'), isFalse);
  });

  test('clears all values', () {
    cache
      ..add('first', 1)
      ..add('second', 2)
      ..clear();

    expect(cache.length, 0);
    expect(cache.keys, isEmpty);
  });
}
