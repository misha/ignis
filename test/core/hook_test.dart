import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

/// A node whose [tick] body can be swapped between frames, which is what a hot
/// reload does to a real one.
final class _Node extends Node {
  void Function(_Node node, double dt) body;

  _Node(this.body);

  @override
  void tick(double dt) => body(this, dt);
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
    test('nothing runs until the first update', () {
      var ticks = 0;
      final scene = _Node((_, _) => ticks += 1).mount();

      expect(ticks, 0, reason: 'mounting no longer runs a pass');

      scene.update(0);
      expect(ticks, 1);
    });

    test('a reassembly is deferred to the next update', () {
      var effects = 0;

      final scene = _Node((node, _) {
        node.fuseEffect(() {
          effects += 1;
          return null;
        });
      }).mount();

      scene.update(0);
      expect(effects, 1);

      scene.update(0);
      expect(effects, 1, reason: 'replay frames skip effects');

      scene.reassemble(.reload);
      expect(effects, 1, reason: 'the walk only marks');

      scene.update(0);
      expect(effects, 2);

      scene.update(0);
      expect(effects, 2, reason: 'one full pass per reassembly');
    });

    test('hooks are unavailable outside a pass', () {
      final node = _Node((_, _) {});

      expect(() => node.fuseState(0), throwsStateError);
    });
  });

  group('fuseState', () {
    test('holds its box across frames and reassemblies', () {
      Ref<int>? state;
      final node = _Node((node, _) => state = node.fuseState(0));
      final scene = node.mount()..update(0);
      final first = state;

      scene.update(0);
      expect(state, same(first));

      scene.reassemble(.reload);
      scene.update(0);
      expect(state, same(first));
    });

    test('keeps its value while the body around it is replaced', () {
      final node = _Node((node, _) => node.fuseState(0).value += 1);
      final scene = node.mount()
        ..update(0)
        ..update(0);

      node.body = (node, _) => node.fuseState(0).value += 10;
      scene.reassemble(.reload);
      scene.update(0);

      Ref<int>? state;
      node.body = (node, _) => state = node.fuseState(0);
      scene.reassemble(.reload);
      scene.update(0);

      expect(state!.value, 12, reason: '1 + 1 from before the edit, 10 after');
    });

    test('a reload may change the slot it holds', () {
      String? value;
      final node = _Node((node, _) => node.fuseState(0));
      final scene = node.mount()..update(0);

      node.body = (node, _) => value = node.fuseState('replaced').value;
      scene.reassemble(.reload);

      final reported = _reported(() => scene.update(0));

      expect(reported, isEmpty);
      expect(value, 'replaced');
    });

    test('an asset refresh may not, since code cannot have changed', () {
      final node = _Node((node, _) => node.fuseState(0));
      final scene = node.mount()..update(0);

      node.body = (node, _) => node.fuseState('replaced');
      scene.reassemble(.assets);

      final reported = _reported(() => scene.update(0));

      expect(reported, hasLength(1));
      expect(reported.single.exception, isStateError);
    });
  });

  group('fuseEffect', () {
    test('cleans up before it re-runs', () {
      final log = <String>[];

      final scene = _Node((node, _) {
        node.fuseEffect(() {
          log.add('run');
          return () => log.add('clean');
        });
      }).mount()..update(0);

      scene.reassemble(.reload);
      scene.update(0);

      expect(log, ['run', 'clean', 'run']);
    });

    test('runs once when keyed on nothing', () {
      final log = <String>[];

      final scene = _Node((node, _) {
        node.fuseEffect(() {
          log.add('run');
          return null;
        }, const []);
      }).mount()..update(0);

      scene.reassemble(.reload);
      scene.update(0);

      expect(log, ['run']);
    });

    test('re-runs when its keys change', () {
      final log = <String>[];
      var key = 'a';

      final scene = _Node((node, _) {
        node.fuseEffect(() {
          log.add(key);
          return null;
        }, [key]);
      }).mount()..update(0);

      scene.reassemble(.reload);
      scene.update(0);
      expect(log, ['a']);

      key = 'b';
      scene.reassemble(.reload);
      scene.update(0);
      expect(log, ['a', 'b']);
    });

    test('cleans up at unmount', () {
      final log = <String>[];

      final scene = _Node((node, _) {
        node.fuseEffect(() {
          return () => log.add('clean');
        });
      }).mount()..update(0);

      scene.destroy();

      expect(log, ['clean']);
    });
  });

  group('shape', () {
    test('a pass declaring fewer hooks disposes the rest', () {
      final log = <String>[];
      var both = true;

      final node = _Node((node, _) {
        node.fuseEffect(() {
          return () => log.add('first');
        }, const []);

        if (both) {
          node.fuseEffect(() {
            return () => log.add('second');
          }, const []);
        }
      });

      final scene = node.mount()..update(0);
      both = false;
      scene.reassemble(.reload);
      scene.update(0);

      expect(log, ['second'], reason: 'only the dropped hook was disposed');
    });

    test('hooks are disposed in reverse order', () {
      final log = <String>[];

      final scene = _Node((node, _) {
        node.fuseEffect(() {
          return () => log.add('a');
        }, const []);
        node.fuseEffect(() {
          return () => log.add('b');
        }, const []);
        node.fuseEffect(() {
          return () => log.add('c');
        }, const []);
      }).mount()..update(0);

      scene.destroy();

      expect(log, ['c', 'b', 'a']);
    });
  });

  group('failure', () {
    test('a throwing tick is reported and contained', () {
      final a = _Node((_, _) {});
      final b = _Node((_, _) {});
      a.add(b);
      final scene = a.mount();
      a.body = (_, _) => throw StateError('mid-edit');

      var ticked = false;
      b.body = (_, _) => ticked = true;

      final reported = _reported(() => scene.update(0));

      expect(reported, hasLength(1));
      expect(reported.single.exception, isStateError);
      expect(ticked, isTrue, reason: 'the frame carried on past the bad node');
    });
  });

  group('fuseChild', () {
    test('adds its child, enqueued like any other mounted tree operation', () {
      final node = _Node((node, _) => node.fuseChild(Node.new));
      final scene = node.mount()..update(0);
      expect(node.children, isEmpty);

      scene.update(0);

      expect(node.children, hasLength(1));
      expect(node.children.single.isMounted, isTrue);
    });

    test('keeps the same child across frames and reassemblies', () {
      final node = _Node((node, _) => node.fuseChild(Node.new));
      final scene = node.mount()
        ..update(0)
        ..update(0);

      final child = node.children.single;
      scene.reassemble(.reload);
      scene.update(0);
      scene.update(0);

      expect(node.children.single, same(child));
    });

    test('replaces its child when its keys change', () {
      var key = 'a';
      final node = _Node((node, _) => node.fuseChild(Node.new, [key]));
      final scene = node.mount()
        ..update(0)
        ..update(0);

      final child = node.children.single;
      key = 'b';
      scene.reassemble(.reload);
      scene.update(0);
      scene.update(0);

      expect(node.children, hasLength(1));
      expect(node.children.single, isNot(same(child)));
      expect(child.isMounted, isFalse);
    });

    test('removes its child at unmount', () {
      final node = _Node((node, _) => node.fuseChild(Node.new));
      final scene = node.mount()
        ..update(0)
        ..update(0);

      final child = node.children.single;
      scene.destroy();

      expect(child.isMounted, isFalse);
    });
  });

  group('fuseSignal', () {
    test('subscribes for the life of the node', () {
      final signal = Signal0();
      var emissions = 0;
      final node = _Node((node, _) => node.fuseSignal0(signal, () => emissions += 1));
      final scene = node.mount()..update(0);

      signal.emit();
      scene.destroy();
      signal.emit();

      expect(emissions, 1);
    });

    test('a reassembly swaps in the handler the pass just built', () {
      final signal = Signal1<int>();
      final log = <String>[];
      var edited = false;

      final node = _Node((node, _) {
        node.fuseSignal1(signal, (value) => log.add('${edited ? 'new' : 'old'} $value'));
      });

      final scene = node.mount()..update(0);
      signal.emit(1);
      edited = true;
      scene.reassemble(.reload);
      scene.update(0);
      signal.emit(2);

      expect(log, ['old 1', 'new 2']);
    });
  });
}
