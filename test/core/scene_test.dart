import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('tracks size and layout state after resize', () {
    final scene = Node().mount();
    scene.resize(100, 80);

    expect(scene.hasSize, isTrue);
    expect(scene.size, Vector2(100, 80));
  });

  test('keeps the given node parentless once loaded', () {
    final node = Node();
    final scene = node.mount();

    expect(scene.node.parent, isNull);
  });
}
