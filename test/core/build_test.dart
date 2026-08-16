import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

/// A node whose [build] body can be swapped between passes, which is what a
/// hot reload does to a real one.
final class _Node extends Node {
  void Function(_Node node) builder;
  int builds = 0;

  _Node(this.builder);

  @override
  void build() {
    builds += 1;
    builder(this);
    super.build();
  }
}

/// Two distinguishable node types, for watching a declaration change shape.
final class _A extends Node {}

final class _B extends Node {}

/// Runs [body] with error reporting captured instead of presented.
List<FlutterErrorDetails> _reported(void Function() body) {
  final reported = <FlutterErrorDetails>[];
  final previous = FlutterError.onError;
  FlutterError.onError = reported.add;

  try {
    body();
  } finally {
    FlutterError.onError = previous;
  }

  return reported;
}

void main() {
  group('passes', () {
    test('build runs on mount', () {
      final node = _Node((_) {})..mount();

      expect(node.builds, 1);
    });

    test('build runs again on every reassembly', () {
      final node = _Node((_) {});
      final scene = node.mount();

      scene.reassemble();
      scene.reassemble();

      expect(node.builds, 3);
    });

    test('a throwing build is reported and contained', () {
      final a = _Node((_) {});
      final b = _Node((_) {});
      a.add(b);
      final scene = a.mount();
      a.builder = (_) => throw StateError('mid-edit');

      final reported = _reported(scene.reassemble);

      expect(reported, hasLength(1));
      expect(reported.single.exception, isStateError);
      expect(b.builds, 2, reason: 'the walk carried on past the bad node');
    });
  });

  group('declarations', () {
    test('discards what a later pass builds for the child already standing', () {
      final node = _Node((n) => n.add(_A()));
      final scene = node.mount()..update(0);
      final first = node.children.single;

      scene.reassemble();
      scene.update(0);

      expect(node.children, hasLength(1));
      expect(node.children.single, same(first));
    });

    test('replaces the standing child when the type changes', () {
      var first = true;
      final node = _Node((n) => n.add(first ? _A() : _B()));
      final scene = node.mount()..update(0);
      final a = node.children.single;

      first = false;
      scene.reassemble();
      scene.update(0);

      expect(a.isMounted, isFalse);
      expect(node.children.single, isA<_B>());
    });

    test('replaces the standing child when its keys change', () {
      var size = 10.0;
      final node = _Node((n) => n.add(_A(), [size]));
      final scene = node.mount()..update(0);
      final a = node.children.single;

      scene.reassemble();
      scene.update(0);
      expect(node.children.single, same(a), reason: 'the key held');

      size = 20.0;
      scene.reassemble();
      scene.update(0);

      expect(a.isMounted, isFalse);
      expect(node.children.single, isNot(same(a)));
    });

    test('truncates what a pass stops declaring', () {
      var both = true;

      final node = _Node((n) {
        n.add(_A());
        if (both) n.add(_B());
      });

      final scene = node.mount()..update(0);
      expect(node.children, hasLength(2));
      final b = node.children.last;

      both = false;
      scene.reassemble();
      scene.update(0);

      expect(node.children, hasLength(1));
      expect(b.isMounted, isFalse);
    });

    test('leaves imperative additions alone', () {
      final node = _Node((n) => n.add(_A()));
      final scene = node.mount()..update(0);
      final spawned = node.add(_B());
      scene.update(0);

      scene.reassemble();
      scene.update(0);

      expect(spawned.isMounted, isTrue, reason: 'no pass declared it');
      expect(node.children, hasLength(2));
    });

    test('refills the position of a child that detached itself', () {
      final node = _Node((n) => n.add(_A()));
      final scene = node.mount()..update(0);
      final a = node.children.single;

      a.detach();
      scene.update(0);
      expect(node.children, isEmpty);

      scene.reassemble();
      scene.update(0);

      expect(node.children, hasLength(1));
      expect(node.children.single, isNot(same(a)));
    });

    test('shifts everything after a declaration inserted above it', () {
      var inserted = false;

      final node = _Node((n) {
        if (inserted) n.add(_B());
        n.add(_A());
      });

      final scene = node.mount()..update(0);
      final a = node.children.single;

      inserted = true;
      scene.reassemble();
      scene.update(0);

      expect(a.isMounted, isFalse, reason: 'position 0 became the _B');
      expect(node.children, hasLength(2));
    });
  });

  group('tick', () {
    test('runs its callback every update', () {
      var elapsed = 0.0;
      final scene = _Node((node) => node.tick << (dt) => elapsed += dt).mount();

      scene.update(0.5);
      scene.update(0.5);

      expect(elapsed, 1);
    });

    test('a reassembly swaps in the callback the pass just built', () {
      final log = <String>[];
      var edited = false;
      final node = _Node((n) => n.tick << (_) => log.add(edited ? 'new' : 'old'));
      final scene = node.mount();

      scene.update(0);
      edited = true;
      scene.reassemble();
      scene.update(0);

      expect(log, ['old', 'new']);
    });

    test('stops once the pass stops declaring it', () {
      var ticks = 0;
      var declared = true;

      final node = _Node((n) {
        if (declared) n.tick << (_) => ticks += 1;
      });

      final scene = node.mount();
      scene.update(0);
      declared = false;
      scene.reassemble();
      scene.update(0);

      expect(ticks, 1);
    });
  });

  group('trash', () {
    test('empties when the pass that filled it is superseded', () {
      final log = <String>[];
      final node = _Node((node) => node.trash << () => log.add('cleaned'));
      final scene = node.mount();

      expect(log, isEmpty, reason: 'the pass is still current');
      scene.reassemble();

      expect(log, ['cleaned']);
    });

    test('empties at unmount', () {
      final log = <String>[];
      final scene = _Node((node) => node.trash << () => log.add('cleaned')).mount();

      scene.destroy();

      expect(log, ['cleaned']);
    });

    test('empties in reverse order', () {
      final log = <String>[];

      final scene = _Node((node) {
        node.trash << () => log.add('a');
        node.trash << () => log.add('b');
        node.trash << () => log.add('c');
      }).mount();

      scene.destroy();

      expect(log, ['c', 'b', 'a']);
    });

    test('a throwing cleanup is reported and contained', () {
      final log = <String>[];

      final scene = _Node((node) {
        node.trash << () => log.add('after');
        node.trash << () => throw StateError('bad');
      }).mount();

      final reported = _reported(scene.destroy);

      expect(reported, hasLength(1));
      expect(reported.single.exception, isStateError);
      expect(log, ['after'], reason: 'the rest of the bag still emptied');
    });
  });

  group('signals', () {
    test('a subscription made in build lives and dies with the node', () {
      final signal = Signal0();
      var emissions = 0;
      final node = _Node((_) => signal(() => emissions += 1));
      final scene = node.mount();

      signal.emit();
      scene.destroy();
      signal.emit();

      expect(emissions, 1);
    });

    test('a reassembly swaps in the handler the pass just built', () {
      final signal = Signal1<int>();
      final log = <String>[];
      var edited = false;

      final node = _Node((_) {
        signal((value) => log.add('${edited ? 'new' : 'old'} $value'));
      });

      final scene = node.mount();
      signal.emit(1);
      edited = true;
      scene.reassemble();
      signal.emit(2);

      expect(log, ['old 1', 'new 2']);
    });

    test('onMount subscribed in build hears the mount that ran it', () {
      var mounted = 0;
      final node = _Node((node) => node.onMount(() => mounted += 1));

      node.mount();

      expect(mounted, 1);
    });

    test('onUnmount subscribed in build fires once, at unmount', () {
      var unmounted = 0;
      final node = _Node((node) => node.onUnmount(() => unmounted += 1));
      final scene = node.mount();

      scene.reassemble();
      scene.destroy();

      expect(unmounted, 1);
    });

    test('onSceneResize subscribed in build hears the mount emission', () {
      final scene = Node().mount();
      scene.resize(100, 80);
      Vector2? heard;
      final node = _Node((node) => node.onSceneResize((size) => heard = size));

      scene.node.add(node);
      scene.update(0);

      expect(heard, Vector2(100, 80));
    });

    test('outside a pass, the caller owns the subscription', () {
      final signal = Signal0();
      var emissions = 0;
      final unwatch = signal(() => emissions += 1);

      signal.emit();
      unwatch();
      signal.emit();

      expect(emissions, 1);
    });
  });
}
