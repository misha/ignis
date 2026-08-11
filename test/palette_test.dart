import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('starts with a default paint, enabled and at the origin', () {
    final paint = Paint();
    final palette = Palette(paint: paint);

    expect(palette.paint.value, same(paint));
    expect(palette.paints, hasLength(1));

    final entry = palette.paints.single;
    expect(entry.name, isNull);
    expect(entry.value, same(paint));
    expect(entry.offset.isZero, isTrue);
    expect(entry.enabled, isTrue);
    expect(entry.priority, 0);
  });

  test('registers and looks up named paints', () {
    final palette = Palette();
    final glow = Paint();
    final entry = palette.add('glow', paint: glow);

    expect(entry.name, 'glow');
    expect(entry.value, same(glow));
    expect(palette['glow'], same(entry));
  });

  test('throws an assertion error for an unregistered name', () {
    final palette = Palette();
    expect(() => palette['missing'], throwsA(isA<AssertionError>()));
  });

  test('throws when a name is already registered', () {
    final palette = Palette();
    palette.add('glow', paint: Paint());

    expect(() => palette.add('glow', paint: Paint()), throwsStateError);
  });

  test('new entries start enabled and at the origin unless overridden', () {
    final palette = Palette();
    final entry = palette.add('glow', paint: Paint());

    expect(entry.enabled, isTrue);
    expect(entry.offset.x, 0);
    expect(entry.offset.y, 0);
    expect(entry.priority, 0);
  });

  test('removes a named paint', () {
    final palette = Palette();
    palette.add('glow', paint: Paint());

    expect(palette.remove('glow'), isTrue);
    expect(() => palette['glow'], throwsA(isA<AssertionError>()));
  });

  test('removing an unregistered name is a no-op that returns false', () {
    final palette = Palette();
    expect(palette.remove('missing'), isFalse);
  });

  test('the default paint has no name, and cannot be removed', () {
    final palette = Palette();

    expect(palette.paints.single.name, isNull);
    expect(palette.remove('default'), isFalse);
    expect(palette.paints, hasLength(1));
  });

  test('orders entries by priority while preserving insertion order for ties', () {
    final palette = Palette();
    final default_ = palette.paints.single;
    final b = palette.add('b', paint: Paint(), priority: 1);
    final c = palette.add('c', paint: Paint(), priority: -1);
    final d = palette.add('d', paint: Paint(), priority: 1);

    expect(palette.paints, [c, default_, b, d]);
  });

  test('reorders entries when their priority changes', () {
    final palette = Palette();
    final default_ = palette.paints.single;
    final b = palette.add('b', paint: Paint());
    final c = palette.add('c', paint: Paint());
    final d = palette.add('d', paint: Paint());

    c.priority = 1;
    expect(palette.paints, [default_, b, d, c]);

    c.priority = 0;
    expect(palette.paints, [default_, b, d, c]);
  });
}
