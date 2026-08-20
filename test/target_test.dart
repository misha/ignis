import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

/// A host that resolves its target from its own build, as every effect does.
final class _Host extends Node {
  late final target = Target<PositionOwner>(this);

  @override
  void build() {
    super.build();
    target.resolve();
  }
}

void main() {
  test('resolves to the nearest ancestor implementing T once mounted', () {
    final node = SpatialNode();
    final host = _Host();

    node.add(host);
    expect(host.target.value, isNull, reason: 'it has not built yet');

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

  test('clears once unmounted', () {
    final node = SpatialNode();
    final host = _Host();

    node.add(host);
    final scene = node.mount();
    expect(host.target.value, same(node));

    host.detach();
    scene.update(0); // Flush the pending removal.
    expect(host.target.value, isNull);
  });

  test('re-resolves against a new parent when the host rebuilds', () {
    final first = SpatialNode();
    final second = SpatialNode();
    final host = _Host();
    first.add(host);
    final scene = first.mount();
    scene.node.add(second);
    expect(host.target.value, same(first));

    host.detach();
    scene.update(0);
    second.add(host);
    scene.update(0);

    expect(host.target.value, same(second));
  });

  test('throws when no ancestor implements T', () {
    final root = Node(); // Doesn't implement PositionOwner.
    final host = _Host();
    root.add(host);

    expect(root.mount, throwsAssertionError);
  });
}
