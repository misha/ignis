import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('distance returns the distance between two nodes\' positions', () {
    final a = TransformNode(position: .zero);
    final b = TransformNode(position: .new(3, 4));

    expect(a.distance(b), 5);
  });

  test('distance2 returns the squared distance between two nodes\' positions', () {
    final a = TransformNode(position: .zero);
    final b = TransformNode(position: .new(3, 4));

    expect(a.distance2(b), 25);
  });

  test('distance measures between absolute positions, not local ones', () {
    final a = TransformNode(position: .zero);
    final b = TransformNode(position: .zero);

    TransformNode(
      position: .new(100, 0),
      children: [a],
    );

    TransformNode(
      position: .new(103, 4),
      children: [b],
    );

    expect(a.distance(b), 5);
    expect(a.distance2(b), 25);
  });

  test('absolutePosition matches position without a parent', () {
    final node = TransformNode(position: .new(3, 4));

    expect(node.absolutePosition, Vector2(3, 4));
  });

  test('absolutePosition composes translation through every ancestor', () {
    final node = TransformNode(position: .new(1, 2));

    TransformNode(
      position: .new(10, 20),
      children: [
        TransformNode(
          position: .new(100, 200),
          children: [node],
        ),
      ],
    );

    expect(node.absolutePosition, Vector2(111, 222));
  });

  test('absolutePosition applies an ancestor\'s scale', () {
    final node = TransformNode(position: .new(3, 4));

    TransformNode(
      position: .new(10, 10),
      scale: .new(2, 3),
      children: [node],
    );

    expect(node.absolutePosition, Vector2(16, 22));
  });

  test('absolutePosition applies an ancestor\'s angle', () {
    final node = TransformNode(position: .new(10, 0));

    TransformNode(
      angle: math.pi / 2,
      children: [node],
    );

    final absolute = node.absolutePosition;

    expect(absolute.x, closeTo(0, 1e-12));
    expect(absolute.y, closeTo(10, 1e-12));
  });

  test('absolutePosition skips ancestors that are not TransformNodes', () {
    final node = TransformNode(position: .new(1, 2));

    TransformNode(
      position: .new(10, 20),
      children: [
        Node(
          children: [node],
        ),
      ],
    );

    expect(node.absolutePosition, Vector2(11, 22));
  });

  test('scenePosition stops at upTo without including it', () {
    final node = TransformNode(position: .new(1, 2));
    late final TransformNode middle;

    TransformNode(
      position: .new(100, 200),
      children: [
        middle = TransformNode(
          position: .new(10, 20),
          children: [node],
        ),
      ],
    );

    expect(node.scenePosition(middle), Vector2(1, 2));
    expect(node.scenePosition(), node.absolutePosition);
  });

  test('absolutePosition agrees with absoluteTransform\'s translation', () {
    final node = TransformNode(
      position: .new(3, 4),
      scale: .new(2, 2),
      angle: 0.75,
    );

    TransformNode(
      position: .new(10, 20),
      scale: .new(1.5, 0.5),
      angle: -0.4,
      children: [
        TransformNode(
          position: .new(5, 6),
          angle: 1.1,
          children: [node],
        ),
      ],
    );

    final transform = node.absoluteTransform();
    final absolute = node.absolutePosition;

    expect(absolute.x, closeTo(transform[6], 1e-12));
    expect(absolute.y, closeTo(transform[7], 1e-12));
  });

  test('absolutePosition returns a fresh vector the caller may mutate', () {
    final node = TransformNode(position: .new(3, 4));
    final absolute = node.absolutePosition..setValues(0, 0);

    expect(node.position, Vector2(3, 4));
    expect(absolute, Vector2.zero);
    expect(node.absolutePosition, isNot(same(absolute)));
  });

  test('nearest finds the closest T in the tree', () {
    final node = TransformNode(position: .zero);
    final near = _Marker(position: .new(1, 0));
    final far = _Marker(position: .new(10, 0));

    Node(children: [node, near, far]);

    expect(node.nearest<_Marker>(), same(near));
  });

  test('nearest searches its own subtree when it has no parent', () {
    final near = _Marker(position: .new(1, 0));
    final node = TransformNode(children: [near]);

    expect(node.nearest<_Marker>(), same(near));
  });

  test('nearest never returns the node it was called on', () {
    final node = _Marker(position: .zero);
    final other = _Marker(position: .new(100, 0));

    Node(children: [node, other]);

    expect(node.nearest<_Marker>(), same(other));
  });

  test('nearest ignores nodes of other types', () {
    final node = TransformNode(position: .zero);
    final other = _Other(position: .new(1, 0));
    final marker = _Marker(position: .new(10, 0));

    Node(children: [node, other, marker]);

    expect(node.nearest<_Marker>(), same(marker));
  });

  test('nearest compares in scene space', () {
    final node = TransformNode(position: .zero);
    final near = _Marker(position: .new(1, 0));
    final far = _Marker(position: .new(5, 0));

    Node(
      children: [
        node,
        TransformNode(
          position: .new(100, 0),
          children: [near],
        ),
        far,
      ],
    );

    // Locally near wins; absolutely it sits at (101, 0) and far wins.
    expect(node.nearest<_Marker>(), same(far));
  });

  test('nearest restricts the search to within', () {
    final node = TransformNode(position: .zero);
    final inside = _Marker(position: .new(10, 0));
    final outside = _Marker(position: .new(1, 0));
    final board = Node(children: [inside]);

    Node(children: [node, board, outside]);

    expect(node.nearest<_Marker>(board), same(inside));
    expect(node.nearest<_Marker>(), same(outside));
  });

  test('nearest never returns within itself', () {
    final node = TransformNode(position: .zero);
    final inside = _Marker(position: .new(10, 0));
    final board = _Marker(
      position: .new(1, 0),
      children: [inside],
    );

    Node(children: [node, board]);

    expect(node.nearest<_Marker>(board), same(inside));
  });

  test('nearest returns null when the tree holds no T', () {
    final node = TransformNode(position: .zero);

    Node(
      children: [
        node,
        _Other(position: .new(1, 0)),
      ],
    );

    expect(node.nearest<_Marker>(), isNull);
  });

  test('nearest agrees with the extension over the same tree', () {
    final node = TransformNode(position: .zero);
    final a = _Marker(position: .new(7, 0));
    final b = _Marker(position: .new(3, 0));

    final root = Node(
      children: [
        node,
        TransformNode(
          position: .new(1, 1),
          children: [a],
        ),
        b,
      ],
    );

    expect(
      node.nearest<_Marker>(),
      same(root.descendants.whereType<_Marker>().nearest(node)),
    );
  });
}

class _Marker extends TransformNode {
  _Marker({
    super.position,
    super.children,
  });
}

class _Other extends TransformNode {
  _Other({
    super.position,
  });
}
