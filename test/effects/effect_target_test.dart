import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

/// A host that resolves its target from its own build, as every effect does.
final class _Host extends Node {
  late final target = EffectTarget<PositionOwner>(this);

  @override
  void build() {
    super.build();
    target.resolve();
  }
}

void main() {
  test('resolves to the nearest ancestor implementing T once mounted', () {
    final transform = TransformNode();
    final host = _Host();

    transform.add(host);
    expect(host.target.value, isNull, reason: 'it has not built yet');

    transform.mount();
    expect(host.target.value, same(transform));
  });

  test('resolves to the nearest matching ancestor, not the outermost', () {
    final outer = TransformNode();
    final inner = TransformNode();
    final host = _Host();
    outer.add(inner);
    inner.add(host);

    outer.mount();
    expect(host.target.value, same(inner));
  });

  test('clears once unmounted', () {
    final transform = TransformNode();
    final host = _Host();

    transform.add(host);
    final scene = transform.mount();
    expect(host.target.value, same(transform));

    host.detach();
    scene.update(0); // Flush the pending removal.
    expect(host.target.value, isNull);
  });

  test('re-resolves against a new parent when the host rebuilds', () {
    final first = TransformNode();
    final second = TransformNode();
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

  test('reports when no ancestor implements T', () {
    final root = Node(); // Doesn't implement PositionOwner.
    final host = _Host();
    root.add(host);

    final reported = <FlutterErrorDetails>[];
    final previous = FlutterError.onError;
    FlutterError.onError = reported.add;

    try {
      root.mount();
    } finally {
      FlutterError.onError = previous;
    }

    // A build that throws is reported rather than thrown, so one bad node
    // cannot take the whole reassembly down with it.
    expect(reported, hasLength(1));
    expect(reported.single.exception, isA<AssertionError>());
  });
}
