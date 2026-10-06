import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/src/cow.dart';

void main() {
  test('iterates the items as they stood when the loop began', () {
    final a = _Item();
    final b = _Item();
    final cow = Cow<_Item>()
      ..insert(0, a)
      ..insert(1, b);

    final seen = <_Item>[];

    for (final item in cow) {
      seen.add(item);
      cow.remove(b);
    }

    expect(seen, [a, b]);
    expect(cow, [a]);
  });

  test('iterates in reverse as the items stood when the loop began', () {
    final a = _Item();
    final b = _Item();
    final cow = Cow<_Item>()
      ..insert(0, a)
      ..insert(1, b);

    final seen = <_Item>[];

    for (final item in cow.reversed) {
      seen.add(item);
      cow.remove(a);
    }

    expect(seen, [b, a]);
    expect(cow, [b]);
  });

  test('inserts at the given index', () {
    final a = _Item();
    final b = _Item();
    final c = _Item();
    final cow = Cow<_Item>()
      ..insert(0, a)
      ..insert(1, c)
      ..insert(1, b);

    expect(cow, [a, b, c]);
  });

  test('removes only what it holds', () {
    final a = _Item();
    final cow = Cow<_Item>()..insert(0, a);

    expect(cow.remove(_Item()), isFalse);
    expect(cow.remove(a), isTrue);
    expect(cow, isEmpty);
  });

  test("keeps a query in the list's order wherever an item is inserted", () {
    final a = _Special();
    final b = _Item();
    final c = _Special();
    final cow = Cow<_Item>()
      ..insert(0, a)
      ..insert(1, b)
      ..insert(2, c);

    final query = cow.query<_Special>();
    expect(query, [a, c]);

    final front = _Special();
    final middle = _Special();
    final end = _Special();

    cow
      ..insert(0, front)
      ..insert(3, middle)
      ..insert(cow.length, end);

    expect(query, [front, a, middle, c, end]);

    cow.remove(a);
    expect(query, [front, middle, c, end]);
  });

  test('returns the same query on every call', () {
    final cow = Cow<_Item>();

    expect(cow.query<_Special>(), same(cow.query<_Special>()));
  });
}

class _Item {}

class _Special extends _Item {}
