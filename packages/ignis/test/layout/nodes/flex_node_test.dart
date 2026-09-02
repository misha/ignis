import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('stretch leaves a fixed-size leaf unresized', () {
    final child = ShapeNode(shape: Rectangle(.new(10, 20)));
    final node = RowNode(crossAxisAlignment: .stretch, children: [child]);
    node.layout(.tight(.new(100, 60)));
    expect((child.position.y, child.height), (0.0, 20.0));
  });

  group('unbounded main axis', () {
    test('a loose-fit flex child with mainAxisSize.min shrink-wraps without error', () {
      final a = ShapeNode(shape: Rectangle.square(10));
      final flexible = BoxNode(
        flex: .flexible(),
        children: [ShapeNode(shape: Rectangle.square(5))],
      );

      final node = RowNode(mainAxisSize: .min, children: [a, flexible]);
      node.layout(.loose(.new(double.infinity, 50)));
      expect(node.width, 15);
    });

    test('a tight-fit flex child throws', () {
      final node = RowNode(
        mainAxisSize: .min,
        children: [BoxNode(flex: .expanded())],
      );

      expect(
        () => node.layout(.loose(.new(double.infinity, 50))),
        throwsAssertionError,
      );
    });

    test('mainAxisSize.max with any flexible child throws', () {
      final node = RowNode(children: [BoxNode(flex: .flexible())]);

      expect(
        () => node.layout(.loose(.new(double.infinity, 50))),
        throwsAssertionError,
      );
    });
  });
}
