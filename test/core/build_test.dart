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

/// A subclass whose build sits in a different frame from its base's.
final class _Derived extends _Node {
  int derivedBuilds = 0;

  _Derived() : super((_) {});

  @override
  void build() {
    derivedBuilds += 1;
    super.build();
  }
}

/// Two distinguishable node types, for watching a declaration change shape.
final class _A extends Node {}

final class _B extends Node {}

/// A node configured entirely by its constructor, as a composed node is.
final class _Sized extends Node {
  final double size;

  _Sized(this.size);
}

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

  group('sources', () {
    test('a node knows the file its build is written in', () {
      final node = _Node((_) {})..mount();

      expect(node.sources, contains(endsWith('build_test.dart')));
    });

    test('a base class build counts as a source of the derived node', () {
      final node = _Derived()..mount();

      expect(node.sources, contains(endsWith('build_test.dart')));
      expect(
        node.sources,
        contains(endsWith('node.dart')),
        reason: "Node.build's own frame is in the chain",
      );
    });

    test('rebuilds only the nodes declared in a changed file', () {
      final a = _Node((_) {});
      final b = _Node((_) {});
      a.add(b);
      final scene = a.mount();
      final builds = b.builds;

      scene.reassemble({'package:nothing/of/ours.dart'});

      expect(a.builds, 1, reason: 'nothing it is written in changed');
      expect(b.builds, builds);
    });

    test('rebuilds everything when the changed set is unknown', () {
      final a = _Node((_) {});
      final b = _Node((_) {});
      a.add(b);
      final scene = a.mount();

      scene.reassemble();

      expect(a.builds, 2);
      expect(b.builds, 2);
    });

    test('rebuilds the whole subtree of the node whose file changed', () {
      final node = _Node((_) {});
      final scene = node.mount();
      final source = node.sources.firstWhere((s) => s.endsWith('build_test.dart'));

      scene.reassemble({source});

      expect(node.builds, 2);
    });
  });

  group('declarations', () {
    test('re-runs constructor arguments, not just statements', () {
      var size = 10.0;
      final node = _Node((n) => n.add(_Sized(size)));
      final scene = node.mount()..update(0);

      expect((node.children.single as _Sized).size, 10);

      size = 20.0;
      scene.reassemble();
      scene.update(0);

      expect((node.children.single as _Sized).size, 20);
    });

    test('returns the node it was given, on every pass', () {
      Node? given;
      Node? returned;

      final node = _Node((n) {
        given = _A();
        returned = n.add(given!);
      });

      final scene = node.mount()..update(0);
      expect(returned, same(given));

      scene.reassemble();
      scene.update(0);

      expect(returned, same(given), reason: 'the fresh one, never a standing one');
      expect(node.children.single, same(given));
    });

    test('destroys the children the previous pass declared', () {
      final node = _Node((n) => n.add(_A()));
      final scene = node.mount()..update(0);
      final first = node.children.single;

      scene.reassemble();
      scene.update(0);

      expect(first.isMounted, isFalse);
      expect(node.children.single, isNot(same(first)));
    });

    test('a child that stops being declared does not come back', () {
      var declared = true;

      final node = _Node((n) {
        if (declared) n.add(_A());
      });

      final scene = node.mount()..update(0);
      expect(node.children, hasLength(1));

      declared = false;
      scene.reassemble();
      scene.update(0);

      expect(node.children, isEmpty);
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
  });

  group('onUpdate', () {
    test('runs its callback every update', () {
      var elapsed = 0.0;
      final scene = _Node((node) => node.onUpdate((dt) => elapsed += dt)).mount();

      scene.update(0.5);
      scene.update(0.5);

      expect(elapsed, 1);
    });

    test('a reassembly swaps in the callback the pass just built', () {
      final log = <String>[];
      var edited = false;
      final node = _Node((n) => n.onUpdate((_) => log.add(edited ? 'new' : 'old')));
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
        if (declared) n.onUpdate((_) => ticks += 1);
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

    test('onSceneResize fires again for the handler a rebuild installed', () {
      final scene = Node().mount()..resize(100, 80);
      final sizes = <Vector2>[];
      final node = _Node((n) => n.onSceneResize(sizes.add));

      scene.node.add(node);
      scene.update(0);
      expect(sizes, [Vector2(100, 80)]);

      scene.reassemble();

      expect(
        sizes,
        [Vector2(100, 80), Vector2(100, 80)],
        reason: 'the new handler had never heard it',
      );
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
