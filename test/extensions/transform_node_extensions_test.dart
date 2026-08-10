import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('returns null for an empty iterable', () {
    expect(<TransformNode>[].nearest(.zero()), isNull);
  });

  test('returns the sole element regardless of distance', () {
    final a = TransformNode(position: .new(100, 100));

    expect([a].nearest(.zero()), same(a));
  });

  test('returns the element whose position is closest to the target', () {
    final a = TransformNode(position: .new(10, 0));
    final b = TransformNode(position: .new(1, 0));
    final c = TransformNode(position: .new(5, 0));

    expect([a, b, c].nearest(.zero()), same(b));
  });

  test('finds the nearest regardless of iteration order', () {
    final a = TransformNode(position: .new(1, 0));
    final b = TransformNode(position: .new(10, 0));
    final c = TransformNode(position: .new(5, 0));

    expect([a, b, c].nearest(.zero()), same(a));
  });
}
