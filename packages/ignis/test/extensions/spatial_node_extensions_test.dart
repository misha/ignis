import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('returns null for an empty iterable', () {
    expect(<SpatialNode>[].nearestTo(.zero), isNull);
  });

  test('returns the sole element regardless of distance', () {
    final a = SpatialNode(position: .all(100));

    expect([a].nearestTo(.zero), same(a));
  });

  test('returns the element whose position is closest to the target', () {
    final a = SpatialNode(position: .new(10, 0));
    final b = SpatialNode(position: .new(1, 0));
    final c = SpatialNode(position: .new(5, 0));

    expect([a, b, c].nearestTo(.zero), same(b));
  });

  test('finds the nearest regardless of iteration order', () {
    final a = SpatialNode(position: .new(1, 0));
    final b = SpatialNode(position: .new(10, 0));
    final c = SpatialNode(position: .new(5, 0));

    expect([a, b, c].nearestTo(.zero), same(a));
  });

  test('compares elements under different parents in scene space', () {
    final a = SpatialNode(position: .new(1, 0));
    final b = SpatialNode(position: .new(5, 0));

    SpatialNode(
      position: .new(100, 0),
      children: [a],
    );

    SpatialNode(
      position: .new(2, 0),
      children: [b],
    );

    // Locally a is nearer to the origin; absolutely b is.
    expect([a, b].nearestTo(.zero), same(b));
  });

  test('accounts for an ancestor\'s scale', () {
    final a = SpatialNode(position: .new(1, 0));
    final b = SpatialNode(position: .new(5, 0));

    SpatialNode(
      scale: .all(20),
      children: [a],
    );

    expect([a, b].nearestTo(.zero), same(b));
  });

  test('accounts for an ancestor\'s angle', () {
    final a = SpatialNode(position: .new(10, 0));
    final b = SpatialNode(position: .new(0, 11));

    SpatialNode(
      angle: math.pi / 2,
      children: [a],
    );

    // The rotation swings a onto (0, 10), leaving it nearer than b.
    expect([a, b].nearestTo(.new(0, 10)), same(a));
  });

  test('nearest measures from the given node\'s absolute center', () {
    final target = SpatialNode(position: .zero);
    final a = SpatialNode(position: .new(1, 0));
    final b = SpatialNode(position: .new(5, 0));

    SpatialNode(
      position: .new(100, 0),
      children: [target],
    );

    SpatialNode(
      position: .new(90, 0),
      children: [a, b],
    );

    // Locally target sits at the origin, next to a; absolutely it sits at
    // (100, 0), where b's (95, 0) beats a's (91, 0).
    expect([a, b].nearest(target), same(b));
  });

  test('nearest never returns the given node itself', () {
    final a = SpatialNode(position: .new(1, 0));
    final b = SpatialNode(position: .new(5, 0));

    expect([a, b].nearest(a), same(b));
  });

  test('nearest returns null when the given node is the only element', () {
    final a = SpatialNode(position: .new(1, 0));

    expect([a].nearest(a), isNull);
  });
}
