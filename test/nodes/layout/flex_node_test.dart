import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/test_layout_node.dart';

void main() {
  group('direction', () {
    test('RowNode lays out along the x axis', () {
      final a = ShapeNode(shape: Rectangle.square(10));
      final b = ShapeNode(shape: Rectangle(.new(20, 10)));
      final node = RowNode(children: [a, b]);
      node.layout(.loose(.all(200)));
      expect([a.position, b.position], [Vector2.zero, Vector2(10, 0)]);
    });

    test('ColumnNode lays out along the y axis', () {
      final a = ShapeNode(shape: Rectangle.square(10));
      final b = ShapeNode(shape: Rectangle(.new(10, 20)));
      final node = ColumnNode(children: [a, b]);
      node.layout(.loose(.all(200)));
      expect([a.position, b.position], [Vector2.zero, Vector2(0, 10)]);
    });
  });

  group('mainAxisAlignment', () {
    (ShapeNode, ShapeNode) children() =>
        (ShapeNode(shape: Rectangle.square(10)), ShapeNode(shape: Rectangle.square(10)));

    test('start packs children at the leading edge', () {
      final (a, b) = children();
      final node = RowNode(children: [a, b]);
      node.layout(.tight(.new(100, 50)));
      expect([a.position.x, b.position.x], [0.0, 10.0]);
    });

    test('end packs children at the trailing edge', () {
      final (a, b) = children();
      final node = RowNode(mainAxisAlignment: .end, children: [a, b]);
      node.layout(.tight(.new(100, 50)));
      expect([a.position.x, b.position.x], [80.0, 90.0]);
    });

    test('center packs children around the middle', () {
      final (a, b) = children();
      final node = RowNode(mainAxisAlignment: .center, children: [a, b]);
      node.layout(.tight(.new(100, 50)));
      expect([a.position.x, b.position.x], [40.0, 50.0]);
    });

    test('spaceBetween puts all the free space between children', () {
      final (a, b) = children();
      final node = RowNode(mainAxisAlignment: .spaceBetween, children: [a, b]);
      node.layout(.tight(.new(100, 50)));
      expect([a.position.x, b.position.x], [0.0, 90.0]);
    });

    test('spaceAround splits free space with half-gaps at the edges', () {
      final (a, b) = children();
      final node = RowNode(mainAxisAlignment: .spaceAround, children: [a, b]);
      node.layout(.tight(.new(100, 50)));
      expect([a.position.x, b.position.x], [20.0, 70.0]);
    });

    test('spaceEvenly splits free space into equal gaps, edges included', () {
      final (a, b) = children();
      final node = RowNode(mainAxisAlignment: .spaceEvenly, children: [a, b]);
      node.layout(.tight(.new(100, 50)));
      expect(a.position.x, closeTo(80 / 3, 1e-9));
      expect(b.position.x, closeTo(80 / 3 * 2 + 10, 1e-9));
    });
  });

  group('crossAxisAlignment', () {
    test('a fixed-size leaf ignores it and sits at the cross-axis start', () {
      final child = ShapeNode(shape: Rectangle.square(10));
      final node = RowNode(crossAxisAlignment: .center, children: [child]);
      node.layout(.tight(.all(100)));
      expect(child.position.y, 0);
    });

    test('start positions a LayoutNode child at the cross-axis start', () {
      final child = TestLayoutNode(sizeToReturn: .new(10, 20));
      final node = RowNode(crossAxisAlignment: .start, children: [child]);
      node.layout(.tight(.new(100, 60)));
      expect(child.position.y, 0);
    });

    test('center positions a LayoutNode child around the cross-axis middle', () {
      final child = TestLayoutNode(sizeToReturn: .new(10, 20));
      final node = RowNode(crossAxisAlignment: .center, children: [child]);
      node.layout(.tight(.new(100, 60)));
      expect(child.position.y, 20);
    });

    test('end positions a LayoutNode child at the cross-axis end', () {
      final child = TestLayoutNode(sizeToReturn: .new(10, 20));
      final node = RowNode(crossAxisAlignment: .end, children: [child]);
      node.layout(.tight(.new(100, 60)));
      expect(child.position.y, 40);
    });

    test('stretch forces a LayoutNode child to fill the cross axis', () {
      final child = TestLayoutNode(sizeToReturn: .new(10, 20));
      final node = RowNode(crossAxisAlignment: .stretch, children: [child]);
      node.layout(.tight(.new(100, 60)));
      expect((child.position.y, child.height), (0.0, 60.0));
    });

    test('stretch leaves a fixed-size leaf unresized', () {
      final child = ShapeNode(shape: Rectangle(.new(10, 20)));
      final node = RowNode(crossAxisAlignment: .stretch, children: [child]);
      node.layout(.tight(.new(100, 60)));
      expect((child.position.y, child.height), (0.0, 20.0));
    });
  });

  group('mainAxisSize', () {
    test('min shrinks the main axis to fit consumed space', () {
      final a = ShapeNode(shape: Rectangle.square(10));
      final b = ShapeNode(shape: Rectangle(.new(20, 10)));
      final node = RowNode(mainAxisSize: .min, children: [a, b]);
      node.layout(.loose(.all(200)));
      expect(node.width, 30);
    });

    test('max (the default) fills the available main axis', () {
      final a = ShapeNode(shape: Rectangle.square(10));
      final node = RowNode(children: [a]);
      node.layout(.loose(.all(200)));
      expect(node.width, 200);
    });
  });

  group('spacing', () {
    test('inserts extra room between adjacent children', () {
      final a = ShapeNode(shape: Rectangle.square(10));
      final b = ShapeNode(shape: Rectangle.square(10));
      final node = RowNode(mainAxisSize: .min, spacing: 5, children: [a, b]);
      node.layout(.loose(.all(200)));
      expect([a.position.x, b.position.x], [0.0, 15.0]);
      expect(node.width, 25);
    });
  });

  group('reverse', () {
    test('accumulates children from the end of the main axis', () {
      final a = ShapeNode(shape: Rectangle.square(10));
      final b = ShapeNode(shape: Rectangle.square(10));
      final node = RowNode(reverse: true, children: [a, b]);
      node.layout(.tight(.new(100, 50)));
      expect([a.position.x, b.position.x], [90.0, 80.0]);
    });
  });

  group('flex distribution', () {
    test('splits leftover space evenly among equal-flex children', () {
      final a = ExpandedNode();
      final b = ExpandedNode();
      final node = RowNode(children: [a, b]);
      node.layout(.tight(.new(100, 50)));
      expect((a.width, b.width), (50.0, 50.0));
    });

    test('splits leftover space proportionally by flex weight', () {
      final a = ExpandedNode(flex: 1);
      final b = ExpandedNode(flex: 3);
      final node = RowNode(children: [a, b]);
      node.layout(.tight(.new(100, 50)));
      expect((a.width, b.width), (25.0, 75.0));
    });

    test('FlexFit.loose only guarantees up to its share, not exactly it', () {
      final a = FlexibleNode(
        fit: .loose,
        children: [
          ShapeNode(
            shape: Rectangle.square(5),
          ),
        ],
      );

      final b = ExpandedNode();
      final node = RowNode(children: [a, b]);
      node.layout(.tight(.new(100, 50)));
      expect((a.width, b.width), (5.0, 50.0));
    });

    test('flex children get zero extra space when non-flex children consume everything', () {
      final fixed = ShapeNode(shape: Rectangle(.new(100, 10)));
      final flexible = ExpandedNode();
      final node = RowNode(children: [fixed, flexible]);
      node.layout(.tight(.new(100, 50)));
      expect(flexible.width, 0);
    });

    test('an empty ExpandedNode acts as a flexible spacer between fixed children', () {
      final a = ShapeNode(shape: Rectangle.square(10));
      final b = ShapeNode(shape: Rectangle.square(10));
      final node = RowNode(children: [a, ExpandedNode(), b]);
      node.layout(.tight(.new(100, 50)));
      expect([a.position.x, b.position.x], [0.0, 90.0]);
    });

    test('ColumnNode distributes flex along the y axis', () {
      final a = ExpandedNode();
      final b = ExpandedNode();
      final node = ColumnNode(children: [a, b]);
      node.layout(.tight(.new(50, 100)));
      expect((a.height, b.height), (50.0, 50.0));
    });
  });

  group('unbounded main axis', () {
    test('a loose-fit flex child with mainAxisSize.min shrink-wraps without error', () {
      final a = ShapeNode(shape: Rectangle.square(10));
      final flexible = FlexibleNode(children: [ShapeNode(shape: Rectangle.square(5))]);
      final node = RowNode(mainAxisSize: .min, children: [a, flexible]);
      node.layout(.loose(.new(double.infinity, 50)));
      expect(node.width, 15);
    });

    test('a tight-fit flex child throws', () {
      final node = RowNode(mainAxisSize: .min, children: [ExpandedNode()]);

      expect(
        () => node.layout(.loose(.new(double.infinity, 50))),
        throwsAssertionError,
      );
    });

    test('mainAxisSize.max with any flexible child throws', () {
      final node = RowNode(children: [FlexibleNode()]);

      expect(
        () => node.layout(.loose(.new(double.infinity, 50))),
        throwsAssertionError,
      );
    });
  });
}
