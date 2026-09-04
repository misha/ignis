import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  group('holding a shape', () {
    test('is a point by default, even under a shaped parent', () {
      final node = SpatialNode();
      ShapeNode(shape: .square(40), children: [node]).mount();

      expect(node.size, Vector2.zero);
    });

    test('holds the shape it is given', () {
      final node = SpatialNode(shape: .rectangle(.new(30, 20)));
      expect(node.size, Vector2(30, 20));
    });

    test('reads its parent when told to and states none', () {
      final node = SpatialNode(inherit: .parent);
      ShapeNode(shape: .square(40), children: [node]).mount();

      expect(node.size, Vector2.all(40));
    });

    test('reads the scene at the root when told to', () {
      final node = SpatialNode(inherit: .scene);
      final scene = node.mount();
      scene.resize(100, 50);

      expect(node.size, Vector2(100, 50));
    });

    test('a stated shape wins over inheritance', () {
      final node = SpatialNode(shape: .square(10), inherit: .parent);
      ShapeNode(shape: .square(40), children: [node]).mount();

      expect(node.size, Vector2.all(10));
    });

    test('setting it to none goes back to inheriting', () {
      final node = SpatialNode(shape: .square(10), inherit: .parent);
      ShapeNode(shape: .square(40), children: [node]).mount();

      node.shape = .none;
      expect(node.size, Vector2.all(40));
    });
  });

  group('anchor', () {
    test('covers no area without a size, so it moves nothing', () {
      final node = SpatialNode(position: .new(10, 20), anchor: .center);

      expect(node.size, Vector2.zero);
      expect(node.absolutePosition, Vector2(10, 20));
    });

    test('puts a child at the parent it is anchored inside, not on its position', () {
      final child = SpatialNode();

      ShapeNode(
        shape: .square(40),
        position: .all(100),
        anchor: .center,
        children: [child],
      ).mount();

      // The parent's box spans (80,80)..(120,120), so its corner is (80, 80).
      expect(child.absolutePosition, Vector2(80, 80));
    });

    test('leaves a child alone while the parent is unanchored', () {
      final child = SpatialNode();

      ShapeNode(
        shape: .square(40),
        position: .all(100),
        children: [child],
      ).mount();

      expect(child.absolutePosition, Vector2(100, 100));
    });

    test('carries through the scale and anchor that follow it', () {
      final child = SpatialNode();

      ShapeNode(
        shape: .square(40),
        position: .all(100),
        anchor: .center,
        scale: .all(2),
        children: [child],
      ).mount();

      // The offset is stated in the parent's own space, so the scale doubles it.
      expect(child.absolutePosition, Vector2(60, 60));
    });

    test('hit tests an anchored area where it is drawn', () {
      final taps = TapInput(shape: .square(10), anchor: .center);
      final root = Node(children: [taps]);

      // The area spans (-5,-5)..(5,5) around the node's position.
      expect(root.hitTest(.zero).firstOrNull, same(taps));
      expect(root.hitTest(.all(4)).firstOrNull, same(taps));
      expect(root.hitTest(.all(6)).firstOrNull, isNull);
    });
  });

  group('pointAt', () {
    test('names a point inside its own box', () {
      final node = SpatialNode(shape: .rectangle(.new(40, 20)));

      expect(node.pointAt(.topLeft), Vector2.zero);
      expect(node.pointAt(.center), Vector2(20, 10));
      expect(node.pointAt(.bottomRight), Vector2(40, 20));
    });

    test('ignores its own anchor, which the transform already carries', () {
      final node = SpatialNode(shape: .square(40), anchor: .center);

      expect(node.pointAt(.center), Vector2.all(20));
    });

    test('places a child on the point it names', () {
      final child = SpatialNode();

      final parent = ShapeNode(
        shape: .square(40),
        position: .all(100),
        anchor: .center,
        children: [child],
      );

      child.position.setFrom(parent.pointAt(.bottomRight));
      parent.mount();

      // The parent's box spans (80,80)..(120,120).
      expect(child.absolutePosition, Vector2(120, 120));
    });

    test('center is the middle of the box', () {
      final node = SpatialNode(shape: .rectangle(.new(40, 20)));

      expect(node.center, Vector2(20, 10));
    });
  });

  test('distance returns the distance between two nodes\' centers', () {
    final a = SpatialNode(position: .zero);
    final b = SpatialNode(position: .new(3, 4));

    expect(a.distance(b), 5);
  });

  test('distance2 returns the squared distance between two nodes\' centers', () {
    final a = SpatialNode(position: .zero);
    final b = SpatialNode(position: .new(3, 4));

    expect(a.distance2(b), 25);
  });

  test('distance measures between absolute centers, not local ones', () {
    final a = SpatialNode(position: .zero);
    final b = SpatialNode(position: .zero);

    SpatialNode(
      position: .new(100, 0),
      children: [a],
    );

    SpatialNode(
      position: .new(103, 4),
      children: [b],
    );

    expect(a.distance(b), 5);
    expect(a.distance2(b), 25);
  });

  test('absolutePosition matches position without a parent', () {
    final node = SpatialNode(position: .new(3, 4));

    expect(node.absolutePosition, Vector2(3, 4));
  });

  test('absolutePosition composes translation through every ancestor', () {
    final node = SpatialNode(position: .new(1, 2));

    SpatialNode(
      position: .new(10, 20),
      children: [
        SpatialNode(
          position: .new(100, 200),
          children: [node],
        ),
      ],
    );

    expect(node.absolutePosition, Vector2(111, 222));
  });

  test('absolutePosition applies an ancestor\'s scale', () {
    final node = SpatialNode(position: .new(3, 4));

    SpatialNode(
      position: .new(10, 10),
      scale: .new(2, 3),
      children: [node],
    );

    expect(node.absolutePosition, Vector2(16, 22));
  });

  test('absolutePosition applies an ancestor\'s angle', () {
    final node = SpatialNode(position: .new(10, 0));

    SpatialNode(
      angle: math.pi / 2,
      children: [node],
    );

    final absolute = node.absolutePosition;

    expect(absolute.x, closeTo(0, 1e-12));
    expect(absolute.y, closeTo(10, 1e-12));
  });

  test('absolutePosition skips ancestors that are not SpatialNodes', () {
    final node = SpatialNode(position: .new(1, 2));

    SpatialNode(
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
    final node = SpatialNode(position: .new(1, 2));
    late final SpatialNode middle;

    SpatialNode(
      position: .new(100, 200),
      children: [
        middle = SpatialNode(
          position: .new(10, 20),
          children: [node],
        ),
      ],
    );

    expect(node.scenePosition(middle), Vector2(1, 2));
    expect(node.scenePosition(), node.absolutePosition);
  });

  test('absolutePosition agrees with absoluteTransform\'s translation', () {
    final node = SpatialNode(
      position: .new(3, 4),
      scale: .new(2, 2),
      angle: 0.75,
    );

    SpatialNode(
      position: .new(10, 20),
      scale: .new(1.5, 0.5),
      angle: -0.4,
      children: [
        SpatialNode(
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

  test('absoluteCenter is the same box however the anchor names it', () {
    final corner = ShapeNode(shape: .square(40), anchor: .topLeft);
    final middle = ShapeNode(shape: .square(40), position: .all(20), anchor: .center);

    Node(children: [corner, middle]).mount();

    expect(corner.absolutePosition, Vector2.zero);
    expect(middle.absolutePosition, Vector2(20, 20));

    expect(corner.absoluteCenter, Vector2(20, 20));
    expect(middle.absoluteCenter, Vector2(20, 20));
    expect(corner.distance(middle), 0);
  });

  test('absolutePosition returns a fresh vector the caller may mutate', () {
    final node = SpatialNode(position: .new(3, 4));
    final absolute = node.absolutePosition..setValues(0, 0);

    expect(node.position, Vector2(3, 4));
    expect(absolute, Vector2.zero);
    expect(node.absolutePosition, isNot(same(absolute)));
  });

  test('nearest measures to a shape\'s center, not its position', () {
    final probe = SpatialNode();
    late final ShapeNode near;

    Node(
      children: [
        probe,
        ShapeNode(shape: .square(40), position: .new(10, 0)),
        near = ShapeNode(shape: .square(4), position: .new(20, 0), anchor: .center),
      ],
    ).mount();

    // By position the square at 10 would win against near's 20. Their centers
    // sit at 30 and 20, so near takes it.
    expect(probe.nearest<ShapeNode>(), same(near));
  });

  test('nearest finds the closest T in the tree', () {
    final node = SpatialNode(position: .zero);
    final near = _Marker(position: .new(1, 0));
    final far = _Marker(position: .new(10, 0));

    Node(children: [node, near, far]);

    expect(node.nearest<_Marker>(), same(near));
  });

  test('nearest searches its own subtree when it has no parent', () {
    final near = _Marker(position: .new(1, 0));
    final node = SpatialNode(children: [near]);

    expect(node.nearest<_Marker>(), same(near));
  });

  test('nearest never returns the node it was called on', () {
    final node = _Marker(position: .zero);
    final other = _Marker(position: .new(100, 0));

    Node(children: [node, other]);

    expect(node.nearest<_Marker>(), same(other));
  });

  test('nearest ignores nodes of other types', () {
    final node = SpatialNode(position: .zero);
    final other = _Other(position: .new(1, 0));
    final marker = _Marker(position: .new(10, 0));

    Node(children: [node, other, marker]);

    expect(node.nearest<_Marker>(), same(marker));
  });

  test('nearest compares in scene space', () {
    final node = SpatialNode(position: .zero);
    final near = _Marker(position: .new(1, 0));
    final far = _Marker(position: .new(5, 0));

    Node(
      children: [
        node,
        SpatialNode(
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
    final node = SpatialNode(position: .zero);
    final inside = _Marker(position: .new(10, 0));
    final outside = _Marker(position: .new(1, 0));
    final board = Node(children: [inside]);

    Node(children: [node, board, outside]);

    expect(node.nearest<_Marker>(board), same(inside));
    expect(node.nearest<_Marker>(), same(outside));
  });

  test('nearest never returns within itself', () {
    final node = SpatialNode(position: .zero);
    final inside = _Marker(position: .new(10, 0));
    final board = _Marker(
      position: .new(1, 0),
      children: [inside],
    );

    Node(children: [node, board]);

    expect(node.nearest<_Marker>(board), same(inside));
  });

  test('nearest returns null when the tree holds no T', () {
    final node = SpatialNode(position: .zero);

    Node(
      children: [
        node,
        _Other(position: .new(1, 0)),
      ],
    );

    expect(node.nearest<_Marker>(), isNull);
  });

  test('nearest agrees with the extension over the same tree', () {
    final node = SpatialNode(position: .zero);
    final a = _Marker(position: .new(7, 0));
    final b = _Marker(position: .new(3, 0));

    final root = Node(
      children: [
        node,
        SpatialNode(
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

class _Marker extends SpatialNode {
  _Marker({
    super.position,
    super.children,
  });
}

class _Other extends SpatialNode {
  _Other({
    super.position,
  });
}
