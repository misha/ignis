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

  test('evicts everything derived from a replaced key', () {
    cache
      ..add('hero.png', 1)
      ..add(Cache.derive('hero.png', '32,32'), 2)
      ..add(Cache.derive('hero.png', '16,16'), 3)
      ..add('villain.png', 4)
      ..add('hero.png', 5);

    expect(cache.contains(Cache.derive('hero.png', '32,32')), isFalse);
    expect(cache.contains(Cache.derive('hero.png', '16,16')), isFalse);
    expect(cache.retrieve<int>('hero.png'), 5);
    expect(cache.retrieve<int>('villain.png'), 4, reason: 'an unrelated key was evicted');
  });

  test('reports how many derived entries it evicted', () {
    cache
      ..add('hero.png', 1)
      ..add(Cache.derive('hero.png', '32,32'), 2)
      ..add(Cache.derive('hero.png', '16,16'), 3);

    expect(cache.evictDerived('hero.png'), 2);
    expect(cache.evictDerived('hero.png'), 0);
    expect(cache.contains('hero.png'), isTrue, reason: 'the base key was evicted too');
  });

  group('notifications', () {
    late int notifications;

    setUp(() {
      notifications = 0;
      cache.addListener(() => notifications += 1);
    });

    test('notifies when a value is added', () {
      cache.add('value', 1);
      expect(notifications, 1);
    });

    test('notifies once when a value is replaced, despite the cascade', () {
      cache
        ..add('hero.png', 1)
        ..add(Cache.derive('hero.png', '32,32'), 2);

      notifications = 0;
      cache.add('hero.png', 3);

      expect(notifications, 1);
    });

    test('notifies only when an eviction removed something', () {
      cache.add('value', 1);
      notifications = 0;

      expect(cache.evict('value'), isTrue);
      expect(notifications, 1);

      expect(cache.evict('value'), isFalse);
      expect(notifications, 1);
    });

    test('notifies only when a derived eviction removed something', () {
      cache
        ..add('hero.png', 1)
        ..add(Cache.derive('hero.png', '32,32'), 2);

      notifications = 0;

      expect(cache.evictDerived('hero.png'), 1);
      expect(notifications, 1);

      expect(cache.evictDerived('hero.png'), 0);
      expect(notifications, 1);
    });

    test('notifies only when a clear removed something', () {
      cache.clear();
      expect(notifications, 0);

      cache
        ..add('value', 1)
        ..clear();

      expect(notifications, 2);
    });
  });
}
