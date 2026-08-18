import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

/// A node whose [build] body can be swapped between builds, which is what a
/// hot reload does to a real one, and which reboots to pick the swap up.
final class _Node extends Node {
  void Function(_Node node) builder;
  int builds = 0;

  _Node(this.builder);

  @override
  void reassemble() => rebuild();

  @override
  void build() {
    super.build();
    builds += 1;
    builder(this);
  }
}

/// A node that answers a reassembly the default way, which is not at all.
final class _Silent extends Node {
  int builds = 0;

  @override
  void build() {
    super.build();
    builds += 1;
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
  group('builds', () {
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

    test('a build that throws on mount throws out of mount', () {
      final node = _Node((_) => throw StateError('no ancestor'));

      expect(node.mount, throwsStateError);
    });

    test('a build that throws on a live add throws out of update', () {
      final root = _Node((_) {});
      final scene = root.mount();
      root.add(_Node((_) => throw StateError('no ancestor')));

      expect(() => scene.update(0), throwsStateError);
    });

    test('a throwing reassembly is reported and contained', () {
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

  group('reassembly', () {
    test('leaves a node that says nothing alone', () {
      final node = _Silent();
      final scene = node.mount();

      scene.reassemble();
      scene.reassemble();

      expect(node.builds, 1, reason: 'only the one on mount');
    });

    test('walks past a node that says nothing to one that does not', () {
      final quiet = _Silent();
      final loud = _Node((_) {});
      quiet.add(loud);
      final scene = quiet.mount();

      scene.reassemble();

      expect(quiet.builds, 1);
      expect(loud.builds, 2, reason: 'the walk carried on through its parent');
    });

    test('leaves out the children a rebuild above just discarded', () {
      late _Node declared;
      final parent = _Node((node) => declared = node.add(_Node((_) {})));
      final scene = parent.mount()..update(0);

      // The one declared on mount, before the rebuild replaces it.
      final first = declared;
      expect(first.builds, 1);

      scene.reassemble();

      expect(parent.builds, 2);
      expect(declared, isNot(same(first)), reason: 'the rebuild declared a new one');
      expect(first.builds, 1, reason: 'the walk skipped the discarded one');
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

    test('returns the node it was given, on every build', () {
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

    test('destroys the children the previous build declared', () {
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

      expect(spawned.isMounted, isTrue, reason: 'no build declared it');
      expect(node.children, hasLength(2));
    });

    test('preserves a child the new build declared again', () {
      final held = _Silent();
      final node = _Node((n) => n.add(held));
      final scene = node.mount()..update(0);

      expect(held.builds, 1);

      scene.reassemble();
      scene.update(0);

      expect(node.children.single, same(held));
      expect(held.isMounted, isTrue, reason: 'it never left the tree');
      expect(held.builds, 1, reason: 'a preserved child is a rebuild boundary');
    });

    test('rebuilds queued before a flush settle to one generation', () {
      final node = _Node((n) => n.add(_A()));
      final scene = node.mount()..update(0);

      scene.reassemble();
      scene.reassemble();
      scene.update(0);

      expect(node.builds, 3);
      expect(node.children, hasLength(1), reason: 'only the last build stuck');
    });

    test('a preserved child still goes when the body stops declaring it', () {
      var declared = true;
      final held = _Silent();

      final node = _Node((n) {
        if (declared) n.add(held);
      });

      final scene = node.mount()..update(0);
      scene.reassemble();
      scene.update(0);

      expect(held.isMounted, isTrue);

      declared = false;
      scene.reassemble();
      scene.update(0);

      expect(node.children, isEmpty);
      expect(held.isMounted, isFalse);
    });
  });

  group('onUpdate', () {
    test('runs its callback every update', () {
      var elapsed = 0.0;
      final scene = _Node((node) => node.tick((dt) => elapsed += dt)).mount();

      scene.update(0.5);
      scene.update(0.5);

      expect(elapsed, 1);
    });

    test('a reassembly swaps in the callback the new build declared', () {
      final log = <String>[];
      var edited = false;
      final node = _Node((n) => n.tick((_) => log.add(edited ? 'new' : 'old')));
      final scene = node.mount();

      scene.update(0);
      edited = true;
      scene.reassemble();
      scene.update(0);

      expect(log, ['old', 'new']);
    });

    test('stops once the build stops declaring it', () {
      var ticks = 0;
      var declared = true;

      final node = _Node((n) {
        if (declared) n.tick((_) => ticks += 1);
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
    test('empties when the build that filled it is superseded', () {
      final log = <String>[];
      final node = _Node((node) => node.trash(() => log.add('cleaned')));
      final scene = node.mount();

      expect(log, isEmpty, reason: 'the build is still current');
      scene.reassemble();

      expect(log, ['cleaned']);
    });

    test('empties at unmount', () {
      final log = <String>[];
      final scene = _Node((node) => node.trash(() => log.add('cleaned'))).mount();

      scene.destroy();

      expect(log, ['cleaned']);
    });

    test('empties in reverse order', () {
      final log = <String>[];

      final scene = _Node((node) {
        node.trash(() => log.add('a'));
        node.trash(() => log.add('b'));
        node.trash(() => log.add('c'));
      }).mount();

      scene.destroy();

      expect(log, ['c', 'b', 'a']);
    });

    test('a throwing cleanup is reported and contained', () {
      final log = <String>[];

      final scene = _Node((node) {
        node.trash(() => log.add('after'));
        node.trash(() => throw StateError('bad'));
      }).mount();

      final reported = _reported(scene.destroy);

      expect(reported, hasLength(1));
      expect(reported.single.exception, isStateError);
      expect(log, ['after'], reason: 'the rest still emptied');
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

    test('a reassembly swaps in the handler the new build declared', () {
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

    test('outside a build, the caller owns the subscription', () {
      final signal = Signal0();
      var emissions = 0;
      final cleanup = signal(() => emissions += 1);

      signal.emit();
      cleanup();
      signal.emit();

      expect(emissions, 1);
    });
  });
}
