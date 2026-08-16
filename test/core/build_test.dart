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

/// A node that subscribes from its constructor, as most engine nodes do.
final class _Subscriber extends Node {
  _Subscriber(Signal0 signal, void Function() handle) {
    signal(handle);
  }
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

  group('live', () {
    test('is unavailable outside a pass', () {
      expect(() => live(#thing, Node.new), throwsStateError);
    });

    test('runs its closure once and keeps the result', () {
      var creations = 0;

      final node = _Node((_) {
        live(#thing, () {
          creations += 1;
          return Node();
        });
      });

      final scene = node.mount();
      scene.reassemble();
      scene.reassemble();

      expect(creations, 1);
    });

    test('hands back the same value on every pass', () {
      Object? kept;
      final node = _Node((_) => kept = live(#thing, Node.new));
      final scene = node.mount();
      final first = kept;

      scene.reassemble();

      expect(kept, same(first));
    });

    test('survives declarations appearing above it', () {
      Object? kept;
      var expanded = false;

      final node = _Node((_) {
        if (expanded) live(#added, Node.new);
        kept = live(#thing, Node.new);
      });

      final scene = node.mount();
      final first = kept;
      expanded = true;

      final reported = _reported(scene.reassemble);

      expect(reported, isEmpty);
      expect(kept, same(first), reason: 'a name does not shift');
    });

    test('a new name is built, an abandoned one is dropped', () {
      var which = #a;
      final node = _Node((n) => n.add(live(which, Node.new)));
      final scene = node.mount()..update(0);
      final first = node.children.single;

      which = #b;
      scene.reassemble();

      expect(node.children.single, isNot(same(first)));
      expect(first.isMounted, isFalse, reason: 'the old name was swept');
    });

    test('adds nothing to the tree by itself', () {
      final node = _Node((_) => live(#thing, () => Node()));
      node.mount();

      expect(node.children, isEmpty);
    });

    test('a swept node is detached, wherever it was parented', () {
      var declared = true;
      late Node holder;

      final node = _Node((n) {
        holder = live(#holder, Node.new);
        n.add(holder);
        if (declared) holder.add(live(#leaf, Node.new));
      });

      final scene = node.mount()..update(0);
      final leaf = holder.children.single;

      declared = false;
      scene.reassemble();
      scene.update(0);

      expect(leaf.isMounted, isFalse);
      expect(holder.children, isEmpty);
    });

    test('a pass that throws sweeps nothing', () {
      Object? kept;

      final node = _Node((_) => kept = live(#thing, Node.new));
      final scene = node.mount();
      final first = kept;
      node.builder = (_) => throw StateError('mid-edit');

      _reported(scene.reassemble);
      node.builder = (_) => kept = live(#thing, Node.new);
      scene.reassemble();

      expect(kept, same(first), reason: 'the failed pass kept its hands off');
    });

    test('two declarations sharing a name are caught', () {
      final node = _Node((_) {
        live(#thing, Node.new);
        live(#thing, Node.new);
      });

      final reported = _reported(node.mount);

      expect(reported, hasLength(1));
      expect(reported.single.exception, isA<AssertionError>());
    });

    test('a value built in a pass keeps its subscriptions to itself', () {
      final signal = Signal0();
      var emissions = 0;

      final node = _Node((_) {
        live(#sub, () => _Subscriber(signal, () => emissions += 1));
      });

      final scene = node.mount();
      scene.reassemble();
      signal.emit();

      expect(emissions, 1, reason: 'the parent pass never took it over');
    });

    test('keeps its value while its keys compare equal', () {
      var size = 100.0;
      var creations = 0;

      final node = _Node((_) {
        live(#thing, () {
          creations += 1;
          return Node();
        }, [size]);
      });

      final scene = node.mount();
      scene.reassemble();
      expect(creations, 1);

      size = 200.0;
      scene.reassemble();

      expect(creations, 2, reason: 'the key changed');
    });

    test('detaches the node its keys replaced', () {
      var size = 100.0;
      final node = _Node((n) => n.add(live(#thing, Node.new, [size])));
      final scene = node.mount()..update(0);
      final first = node.children.single;

      size = 200.0;
      scene.reassemble();

      expect(first.isMounted, isFalse);
      expect(node.children.single, isNot(same(first)));
    });

    test('treats two NaN keys as equal, and 0.0 and -0.0 as different', () {
      var key = double.nan;
      var creations = 0;

      final node = _Node((_) {
        live(#thing, () {
          creations += 1;
          return Node();
        }, [key]);
      });

      final scene = node.mount();
      key = double.nan;
      scene.reassemble();
      expect(creations, 1, reason: 'NaN would never equal itself');

      key = 0.0;
      scene.reassemble();
      key = -0.0;
      scene.reassemble();

      expect(creations, 3, reason: 'equal, but not the same key');
    });

    test('keeps anything, not just nodes', () {
      late List<int> kept;
      final node = _Node((_) => kept = live(#list, () => <int>[]));
      final scene = node.mount();
      final first = kept;
      kept.add(1);

      scene.reassemble();

      expect(kept, same(first));
      expect(kept, [1]);
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
