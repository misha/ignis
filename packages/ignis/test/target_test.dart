import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/test_node.dart';

/// A host that builds its target where every effect does, in its constructor.
final class _Host extends Node {
  late final Target<PositionOwner> target;

  _Host() {
    target = Target<PositionOwner>(this);
  }
}

void main() {
  test('resolves to the nearest ancestor implementing T once mounted', () {
    final node = SpatialNode();
    final host = _Host();

    node.add(host);
    expect(() => host.target.value, throwsStateError, reason: 'it has not mounted yet');

    node.mount();
    expect(host.target.value, same(node));
  });

  test('resolves to the nearest matching ancestor, not the outermost', () {
    final outer = SpatialNode();
    final inner = SpatialNode();
    final host = _Host();
    outer.add(inner);
    inner.add(host);

    outer.mount();
    expect(host.target.value, same(inner));
  });

  test('stops resolving once unmounted', () {
    final node = SpatialNode();
    final host = _Host();

    node.add(host);
    final scene = node.mount();
    expect(host.target.value, same(node));

    host.detach();
    scene.update(0); // Flush the pending removal.

    expect(() => host.target.value, throwsStateError);
  });

  test('follows the host when it moves to a new parent', () {
    final first = SpatialNode();
    final second = SpatialNode();
    final host = _Host();
    first.add(host);
    final scene = first.mount();
    first.add(second);
    scene.update(0);
    expect(host.target.value, same(first));

    second.add(host);
    scene.update(0);

    expect(host.target.value, same(second), reason: 'a move re-resolves it');
  });

  test('throws when no ancestor implements T', () {
    final root = Node(); // Doesn't implement PositionOwner.
    final host = _Host();
    root.add(host);

    expect(root.mount, throwsStateError);
  });

  test('a kept effect follows the host its container was rebuilt into', () {
    late SpinEffect effect;
    late ShapeNode host;

    final root = LiveTestNode(
      builder: (node) {
        effect = node.keep(#spin, () => SpinEffect(speed: 1));
        host = node.add(ShapeNode(shape: .square(10), children: [effect]));
      },
    );

    final scene = root.mount()..update(0);
    final dead = host;

    scene.reassemble();
    scene.update(1);

    expect(host, isNot(same(dead)), reason: 'the container was rebuilt');
    expect(effect.target, same(host));
    expect(host.angle, 1.0, reason: 'it drives the host it now sits under');
    expect(dead.angle, 0.0, reason: 'and not the detached one');
  });
}
