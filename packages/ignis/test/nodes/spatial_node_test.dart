import 'dart:math' as math;

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/canvas.dart';
import '../support/colors.dart';
import '../support/test_node.dart';

void main() {
  group('inheriting a shape', () {
    test('takes the shape in effect at its parent', () {
      final node = SpatialNode();
      final slot = ShapeNode(shape: .rectangle(.new(30, 20)), children: [node]);

      slot.mount();

      expect(node.shape, isA<Rectangle>());
      expect(node.size, Vector2(30, 20));
    });

    test('covers no area with nothing above, even in a sized scene', () {
      final node = SpatialNode();
      final scene = node.mount();
      scene.resize(100, 50);

      expect(node.size, Vector2.zero);
    });

    test('follows that shape as it changes', () {
      final node = SpatialNode();
      final slot = ShapeNode(shape: .rectangle(.new(30, 20)), children: [node]);

      slot.mount();
      slot.shape = .rectangle(.new(50, 40));

      expect(node.size, Vector2(50, 40));
    });

    test('takes the nearest shape, not an outer one', () {
      final node = SpatialNode();
      final inner = ShapeNode(shape: .square(10), children: [node]);

      ShapeNode(shape: .square(80), children: [inner]).mount();

      expect(node.size, Vector2.all(10));
    });

    test('reaches through a node that states no shape', () {
      final node = SpatialNode();
      final pivot = SpatialNode(children: [node]);

      ShapeNode(shape: .circle(15), children: [pivot]).mount();

      expect(node.shape, isA<Circle>());
    });

    test('reaches through a node that is not spatial', () {
      final node = SpatialNode();
      final group = Node(children: [node]);

      ShapeNode(shape: .circle(15), children: [group]).mount();

      expect(node.shape, isA<Circle>());
    });

    test('takes a circle from a circle, not a box around it', () {
      final node = SpatialNode();

      ShapeNode(shape: .circle(15), children: [node]).mount();

      expect(node.shape, isA<Circle>());
      expect(node.size, Vector2.all(30));
    });

    test('covers nothing with no shape anywhere above it', () {
      final node = SpatialNode();

      node.mount();

      expect(node.size, Vector2.zero);
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

  group('opacity', () {
    test('takes no layer at all at opacity 1', () {
      final layer = SpatialNode(
        children: [
          ShapeNode(
            shape: .square(50),
            paint: Paint()..color = RED,
          ),
        ],
      );

      layer.mount();
      final canvas = RecordingCanvas();
      layer.render(canvas);

      expect(canvas.saveLayers, 0);
    });

    test('takes one layer at mid opacity', () {
      final layer = SpatialNode(
        opacity: 0.5,
        children: [
          ShapeNode(
            shape: .square(50),
            paint: Paint()..color = RED,
          ),
        ],
      );

      layer.mount();
      final canvas = RecordingCanvas();
      layer.render(canvas);

      expect(canvas.saveLayers, 1);
    });

    test('skips the subtree entirely at opacity 0', () {
      final child = TestNode();
      final layer = SpatialNode(opacity: 0, children: [child]);

      layer.mount();
      layer.render(RecordingCanvas());

      expect(child.renders, 0);
    });

    test('never renders a disabled child into the layer', () {
      final child = TestNode(enabled: false);
      final layer = SpatialNode(opacity: 0.5, children: [child]);

      layer.mount();
      layer.render(RecordingCanvas());

      expect(child.renders, 0);
    });

    test('clamps to the 0..1 range', () {
      final layer = SpatialNode(opacity: 0.5);

      layer.opacity = 1.5;
      expect(layer.opacity, 1);

      layer.opacity = -0.2;
      expect(layer.opacity, 0);
    });
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
