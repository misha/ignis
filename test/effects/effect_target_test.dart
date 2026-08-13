import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('resolves to the nearest ancestor implementing T once mounted', () {
    final transform = TransformNode();
    final host = Node();
    final target = EffectTarget<PositionOwner>(host);

    transform.add(host);
    expect(target.value, isNull); // Not mounted yet.

    transform.mount();
    expect(target.value, same(transform));
  });

  test('resolves to the nearest matching ancestor, not the outermost', () {
    final outer = TransformNode();
    final inner = TransformNode();
    final host = Node();
    outer.add(inner);
    inner.add(host);

    final target = EffectTarget<PositionOwner>(host);

    outer.mount();
    expect(target.value, same(inner));
  });

  test('clears once unmounted', () {
    final transform = TransformNode();
    final host = Node();
    final target = EffectTarget<PositionOwner>(host);

    transform.add(host);
    final scene = transform.mount();
    expect(target.value, same(transform));

    host.detach();
    scene.update(0); // Flush the pending removal.
    expect(target.value, isNull);
  });

  test('asserts when no ancestor implements T', () {
    final root = Node(); // Doesn't implement PositionOwner.
    final host = Node();
    EffectTarget<PositionOwner>(host);
    root.add(host);

    expect(() => root.mount(), throwsAssertionError);
  });
}
