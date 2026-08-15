import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('starts with a default paint, enabled and at the origin', () {
    final paint = Paint();
    final palette = Palette(paint: paint);

    expect(palette.paint, same(paint));
    expect(palette.entries, hasLength(1));

    final entry = palette.entries.single;
    expect(entry.name, isNull);
    expect(entry.paint, same(paint));
    expect(entry.offset.isZero, isTrue);
    expect(entry.enabled, isTrue);
    expect(entry.priority, 0);
  });

  test('registers and looks up named paints', () {
    final palette = Palette();
    final glow = Paint();
    final entry = palette.add(.new('glow', glow));

    expect(entry.name, 'glow');
    expect(entry.paint, same(glow));
    expect(palette['glow'], same(glow));
  });

  test('throws for an unregistered name', () {
    final palette = Palette();
    expect(() => palette['missing'], throwsStateError);
  });

  test('throws when a name is already registered', () {
    final palette = Palette();
    palette.add(.new('glow', Paint()));

    expect(() => palette.add(.new('glow', Paint())), throwsStateError);
  });

  test('throws when an entry is already registered in a palette', () {
    final palette = Palette();
    final PaletteEntry entry = .new('glow', Paint());
    palette.add(entry);

    expect(() => Palette().add(entry), throwsStateError);
  });

  test('new entries start enabled and at the origin unless overridden', () {
    final palette = Palette();
    final entry = palette.add(.new('glow', Paint()));

    expect(entry.enabled, isTrue);
    expect(entry.offset.x, 0);
    expect(entry.offset.y, 0);
    expect(entry.priority, 0);
  });

  test('removes a named paint', () {
    final palette = Palette();
    palette.add(.new('glow', Paint()));

    expect(palette.remove('glow'), isTrue);
    expect(() => palette['glow'], throwsStateError);
  });

  test('removing an unregistered name is a no-op that returns false', () {
    final palette = Palette();
    expect(palette.remove('missing'), isFalse);
  });

  test('the default paint has no name, and cannot be removed', () {
    final palette = Palette();

    expect(palette.entries.single.name, isNull);
    expect(palette.remove('default'), isFalse);
    expect(palette.entries, hasLength(1));
  });

  test('orders entries by priority while preserving insertion order for ties', () {
    final palette = Palette();
    final first = palette.entries.single;
    final b = palette.add(.new('b', Paint(), priority: 1));
    final c = palette.add(.new('c', Paint(), priority: -1));
    final d = palette.add(.new('d', Paint(), priority: 1));

    expect(palette.entries, [c, first, b, d]);
  });

  test('reorders entries when their priority changes', () {
    final palette = Palette();
    final first = palette.entries.single;
    final b = palette.add(.new('b', Paint()));
    final c = palette.add(.new('c', Paint()));
    final d = palette.add(.new('d', Paint()));

    c.priority = 1;
    expect(palette.entries, [first, b, d, c]);

    c.priority = 0;
    expect(palette.entries, [first, b, d, c]);
  });

  test('entry() returns the default entry, or the entry registered under a name', () {
    final palette = Palette();
    final first = palette.entries.single;
    final glow = palette.add(.new('glow', Paint()));

    expect(palette.entry(), same(first));
    expect(palette.entry('glow'), same(glow));
  });
}
