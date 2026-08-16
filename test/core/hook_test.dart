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

/// A hook that logs its [name] when disposed, kept alive by empty keys.
final class _LogHook extends Hook<void> {
  final List<String> log;
  final String name;

  const _LogHook(this.log, this.name) : super(keys: const []);

  @override
  _LogHookState createState() => .new();
}

final class _LogHookState extends HookState<void, _LogHook> {
  @override
  void build() {
    // Nothing to do.
  }

  @override
  void dispose() => hook.log.add(hook.name);
}

/// A node that subscribes from its constructor, as most engine nodes do.
final class _Subscriber extends Node {
  _Subscriber(Signal0 signal, void Function() handle) {
    signal(handle);
  }
}

/// A hook that declares another hook while its own slot is still being filled.
final class _NestingHook extends Hook<void> {
  const _NestingHook() : super(keys: const []);

  @override
  _NestingHookState createState() => .new();
}

final class _NestingHookState extends HookState<void, _NestingHook> {
  @override
  void initHook() => node.on(const _NestingHook());

  @override
  void build() {
    // Nothing to do.
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

      scene.reassemble(.reload);
      scene.reassemble(.assets);

      expect(node.builds, 3);
    });

    test('hooks are unavailable outside a pass', () {
      final node = _Node((_) {});

      expect(() => node.child(Node.new), throwsStateError);
    });
  });

  group('shape', () {
    test('a pass declaring fewer hooks disposes the rest', () {
      final log = <String>[];
      var both = true;

      final node = _Node((node) {
        node.on(_LogHook(log, 'first'));
        if (both) node.on(_LogHook(log, 'second'));
      });

      final scene = node.mount();
      both = false;
      scene.reassemble(.reload);

      expect(log, ['second'], reason: 'only the dropped hook was disposed');
    });

    test('hooks are disposed in reverse order', () {
      final log = <String>[];

      final scene = _Node((node) {
        node.on(_LogHook(log, 'a'));
        node.on(_LogHook(log, 'b'));
        node.on(_LogHook(log, 'c'));
      }).mount();

      scene.destroy();

      expect(log, ['c', 'b', 'a']);
    });

    test('a reload may change which hooks a pass declares', () {
      String? value;
      final node = _Node((node) => node.on(_LogHook([], 'x')));
      final scene = node.mount();
      node.builder = (node) => value = node.child(Node.new).toString();

      final reported = _reported(() => scene.reassemble(.reload));

      expect(reported, isEmpty);
      expect(value, isNotNull);
    });

    test('an asset refresh may not, since code cannot have changed', () {
      final node = _Node((node) => node.on(_LogHook([], 'x')));
      final scene = node.mount();
      node.builder = (node) => node.child(Node.new);

      final reported = _reported(() => scene.reassemble(.assets));

      expect(reported, hasLength(1));
      expect(reported.single.exception, isStateError);
    });
  });

  group('failure', () {
    test('a throwing build is reported and contained', () {
      final a = _Node((_) {});
      final b = _Node((_) {});
      a.add(b);
      final scene = a.mount();
      a.builder = (_) => throw StateError('mid-edit');

      final reported = _reported(() => scene.reassemble(.reload));

      expect(reported, hasLength(1));
      expect(reported.single.exception, isStateError);
      expect(b.builds, 2, reason: 'the walk carried on past the bad node');
    });

    test('a hook declared from inside another one is refused', () {
      final node = _Node((node) => node.on(const _NestingHook()));

      final reported = _reported(() => node.mount());

      expect(reported, hasLength(1));
      expect(reported.single.exception, isStateError);
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
      final node = _Node((node) => node.onUpdate((_) => log.add(edited ? 'new' : 'old')));
      final scene = node.mount();

      scene.update(0);
      edited = true;
      scene.reassemble(.reload);
      scene.update(0);

      expect(log, ['old', 'new']);
    });

    test('stops once the pass stops declaring it', () {
      var ticks = 0;
      var declared = true;

      final node = _Node((node) {
        if (declared) node.onUpdate((_) => ticks += 1);
      });

      final scene = node.mount();
      scene.update(0);
      declared = false;
      scene.reassemble(.reload);
      scene.update(0);

      expect(ticks, 1);
    });
  });

  group('child', () {
    test('adds its child, enqueued like any other mounted tree operation', () {
      final node = _Node((node) => node.child(Node.new));
      final scene = node.mount();
      expect(node.children, isEmpty);

      scene.update(0);

      expect(node.children, hasLength(1));
      expect(node.children.single.isMounted, isTrue);
    });

    test('keeps the same child across a reassembly', () {
      final node = _Node((node) => node.child(Node.new));
      final scene = node.mount()..update(0);
      final child = node.children.single;

      scene.reassemble(.reload);

      expect(node.children.single, same(child));
    });

    test('replaces its child when its keys change', () {
      var key = 'a';
      final node = _Node((node) => node.child(Node.new, [key]));
      final scene = node.mount()..update(0);
      final child = node.children.single;

      key = 'b';
      scene.reassemble(.reload);

      expect(node.children, hasLength(1));
      expect(node.children.single, isNot(same(child)));
      expect(child.isMounted, isFalse);
    });

    test('removes its child at unmount', () {
      final node = _Node((node) => node.child(Node.new));
      final scene = node.mount()..update(0);
      final child = node.children.single;

      scene.destroy();

      expect(child.isMounted, isFalse);
    });

    test('a child keeps its constructor subscriptions to itself', () {
      final signal = Signal0();
      var emissions = 0;

      final node = _Node((node) {
        node.child(() => _Subscriber(signal, () => emissions += 1));
        node.on(_LogHook([], 'tail'));
      });

      final scene = node.mount();
      final reported = _reported(() => scene.reassemble(.assets));

      signal.emit();

      expect(reported, isEmpty, reason: 'the slots kept their declared order');
      expect(emissions, 1);
    });
  });

  group('trash', () {
    test('empties when the pass that filled it is superseded', () {
      final log = <String>[];
      final node = _Node((node) => node.trash << () => log.add('cleaned'));
      final scene = node.mount();

      expect(log, isEmpty, reason: 'the pass is still current');
      scene.reassemble(.reload);

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

    test('may be filled conditionally, unlike a hook', () {
      final log = <String>[];
      var defer = true;

      final node = _Node((node) {
        if (defer) node.trash << () => log.add('cleaned');
      });

      final scene = node.mount();
      defer = false;
      final reported = _reported(() => scene.reassemble(.assets));

      expect(reported, isEmpty, reason: 'the bag has no shape to change');
      expect(log, ['cleaned']);

      scene.destroy();

      expect(log, ['cleaned'], reason: 'the pass that stopped deferring left nothing');
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
      scene.reassemble(.reload);
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

      scene.reassemble(.reload);
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
