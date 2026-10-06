import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'package:flutter/foundation.dart';

import '../support/test_node.dart';

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

/// Two distinguishable node types, for watching a declaration change shape.
final class _A extends Node {}

final class _B extends Node {}

/// A node that subscribes to [signal] in its constructor.
final class _Listener extends Node {
  int heard = 0;

  _Listener(Signal0 signal) {
    signal(() => heard += 1);
  }
}

/// A node configured entirely by its constructor, as a composed node is.
final class _Sized extends Node {
  final double size;

  _Sized(this.size);
}

void main() {
  group('builds', () {
    test('build runs on mount', () {
      final node = LiveTestNode(builder: (_) {})..mount();

      expect(node.builds, 1);
    });

    test('build runs again on every reassembly', () {
      final node = LiveTestNode(builder: (_) {});
      final scene = node.mount();

      scene.reassemble();
      scene.reassemble();

      expect(node.builds, 3);
    });

    test('a build that throws on mount throws out of mount', () {
      final node = LiveTestNode(builder: (_) => throw StateError('no ancestor'));

      expect(node.mount, throwsStateError);
    });

    test('a build that throws on a live add throws out of add', () {
      final root = LiveTestNode(builder: (_) {});
      root.mount();

      expect(
        () => root.add(LiveTestNode(builder: (_) => throw StateError('no ancestor'))),
        throwsStateError,
      );
    });

    test('a throwing reassembly is reported and contained', () {
      final a = LiveTestNode(builder: (_) {});
      final b = LiveTestNode(builder: (_) {});
      a.add(b);
      final scene = a.mount();
      a.builder = (_) => throw StateError('mid-edit');

      final reported = _reported(scene.reassemble);

      expect(reported, hasLength(1));
      expect(reported.single.exception, isStateError);
      expect(b.builds, 2, reason: 'the walk carried on past the bad node');
    });
  });

  group('declaring', () {
    test('asserts on a tick before the node has built', () {
      expect(() => Node().tick((_) {}), throwsAssertionError);
    });

    test('asserts on a declaration once the build has returned', () {
      final node = TestNode()..mount();

      expect(() => node.tick((_) {}), throwsAssertionError);
      expect(() => node.draw((_) {}), throwsAssertionError);
      expect(() => node.debugDraw((_) {}), throwsAssertionError);
      expect(() => node.trash(() {}), throwsAssertionError);
    });

    test('asserts on a tick aimed at another node from a build', () {
      final child = Node();
      final parent = TestNode(builder: (_) => child.tick((_) {}));

      expect(parent.mount, throwsAssertionError);
    });
  });

  group('reassembly', () {
    test('rebuilds every node that mixes in Live', () {
      final child = LiveTestNode(builder: (_) {});
      final parent = LiveTestNode(builder: (node) => node.add(child));
      final scene = parent.mount();

      scene.reassemble();

      expect(parent.builds, 2);
      expect(child.builds, 2);
    });

    test('holds the body of a node without Live', () {
      final quiet = TestNode();
      final scene = quiet.mount();

      scene.reassemble();
      scene.reassemble();

      expect(quiet.builds, 1, reason: 'only the one on mount');
    });

    test('walks past a node without Live to one with it', () {
      final loud = LiveTestNode(builder: (_) {});
      final quiet = TestNode()..add(loud);
      final scene = quiet.mount();

      scene.reassemble();

      expect(quiet.builds, 1);
      expect(loud.builds, 2, reason: 'the walk carried on through its parent');
    });

    test('leaves out the children a rebuild above just discarded', () {
      late LiveTestNode declared;
      final parent = LiveTestNode(
        builder: (node) => declared = node.add(LiveTestNode(builder: (_) {})),
      );
      final scene = parent.mount();

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
      final node = LiveTestNode(builder: (n) => n.add(_Sized(size)));
      final scene = node.mount();

      expect((node.children.single as _Sized).size, 10);

      size = 20.0;
      scene.reassemble();

      expect((node.children.single as _Sized).size, 20);
    });

    test('returns the node it was given, on every build', () {
      Node? given;
      Node? returned;

      final node = LiveTestNode(
        builder: (n) {
          given = _A();
          returned = n.add(given!);
        },
      );

      final scene = node.mount();
      expect(returned, same(given));

      scene.reassemble();

      expect(returned, same(given), reason: 'the newly declared instance');
      expect(node.children.single, same(given));
    });

    test('destroys the children the previous build declared', () {
      final node = LiveTestNode(builder: (n) => n.add(_A()));
      final scene = node.mount();
      final first = node.children.single;

      scene.reassemble();

      expect(first.isMounted, isFalse);
      expect(node.children.single, isNot(same(first)));
    });

    test('a remount replaces the children the previous build declared', () {
      final node = TestNode(builder: (n) => n.add(_A()));
      final root = Node(children: [node]);
      root.mount();
      final first = node.children.single;

      root.remove(node);
      root.add(node);

      expect(first.isMounted, isFalse);
      expect(node.children.single, isNot(same(first)));
    });

    test('a remount into a new scene replaces the children the previous build declared', () {
      final node = TestNode(builder: (n) => n.add(_A()));
      final scene = node.mount();
      final first = node.children.single;

      scene.destroy();
      node.mount();

      expect(first.isMounted, isFalse);
      expect(node.children.single, isNot(same(first)));
    });

    test('a remount leaves imperative additions alone', () {
      final node = TestNode(builder: (n) => n.add(_A()));
      final root = Node(children: [node]);
      root.mount();
      final spawned = node.add(_B());

      root.remove(node);
      root.add(node);

      expect(spawned.isMounted, isTrue, reason: 'no build declared it');
      expect(node.children, hasLength(2));
    });

    test('a child that stops being declared does not come back', () {
      var declared = true;

      final node = LiveTestNode(
        builder: (n) {
          if (declared) n.add(_A());
        },
      );

      final scene = node.mount();
      expect(node.children, hasLength(1));

      declared = false;
      scene.reassemble();

      expect(node.children, isEmpty);
    });

    test('leaves imperative additions alone', () {
      final node = LiveTestNode(builder: (n) => n.add(_A()));
      final scene = node.mount();
      final spawned = node.add(_B());

      scene.reassemble();

      expect(spawned.isMounted, isTrue, reason: 'no build declared it');
      expect(node.children, hasLength(2));
    });

    test('preserves a child the new build declared again', () {
      final held = TestNode();
      final node = LiveTestNode(builder: (n) => n.add(held));
      final scene = node.mount();

      expect(held.builds, 1);

      scene.reassemble();

      expect(node.children.single, same(held));
      expect(held.isMounted, isTrue, reason: 'it never left the tree');
      expect(held.builds, 1, reason: 'a node without Live holds its body');
    });

    test("repeated reassemblies keep only the last build's children", () {
      final node = LiveTestNode(builder: (n) => n.add(_A()));
      final scene = node.mount();

      scene.reassemble();
      scene.reassemble();

      expect(node.builds, 3);
      expect(node.children, hasLength(1), reason: 'only the last build stuck');
    });

    test('a preserved child still goes when the body stops declaring it', () {
      var declared = true;
      final held = TestNode();

      final node = LiveTestNode(
        builder: (n) {
          if (declared) n.add(held);
        },
      );

      final scene = node.mount();
      scene.reassemble();

      expect(held.isMounted, isTrue);

      declared = false;
      scene.reassemble();

      expect(node.children, isEmpty);
      expect(held.isMounted, isFalse);
    });

    test('a self-add reported by a reassembly leaves the node in place', () {
      var broken = false;

      final node = LiveTestNode(
        builder: (n) {
          if (broken) n.add(n);
        },
      );

      final root = Node(children: [node]);
      final scene = root.mount();

      broken = true;
      _reported(scene.reassemble);
      broken = false;
      scene.reassemble();

      expect(node.parent, same(root));
      expect(node.isMounted, isTrue);
    });
  });

  group('onUpdate', () {
    test('runs its callback every update', () {
      var elapsed = 0.0;
      final scene = LiveTestNode(builder: (node) => node.tick((dt) => elapsed += dt)).mount();

      scene.update(0.5);
      scene.update(0.5);

      expect(elapsed, 1);
    });

    test('a reassembly swaps in the callback the new build declared', () {
      final log = <String>[];
      var edited = false;
      final node = LiveTestNode(builder: (n) => n.tick((_) => log.add(edited ? 'new' : 'old')));
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

      final node = LiveTestNode(
        builder: (n) {
          if (declared) n.tick((_) => ticks += 1);
        },
      );

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
      final node = LiveTestNode(builder: (node) => node.trash(() => log.add('cleaned')));
      final scene = node.mount();

      expect(log, isEmpty, reason: 'the build is still current');
      scene.reassemble();

      expect(log, ['cleaned']);
    });

    test('empties at unmount', () {
      final log = <String>[];
      final scene = LiveTestNode(builder: (node) => node.trash(() => log.add('cleaned'))).mount();

      scene.destroy();

      expect(log, ['cleaned']);
    });

    test('empties in reverse order', () {
      final log = <String>[];

      final scene = LiveTestNode(
        builder: (node) {
          node.trash(() => log.add('a'));
          node.trash(() => log.add('b'));
          node.trash(() => log.add('c'));
        },
      ).mount();

      scene.destroy();

      expect(log, ['c', 'b', 'a']);
    });

    test('a throwing cleanup is reported and contained', () {
      final log = <String>[];

      final scene = LiveTestNode(
        builder: (node) {
          node.trash(() => log.add('after'));
          node.trash(() => throw StateError('bad'));
        },
      ).mount();

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
      final node = LiveTestNode(builder: (_) => signal(() => emissions += 1));
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

      final node = LiveTestNode(
        builder: (_) {
          signal((value) => log.add('${edited ? 'new' : 'old'} $value'));
        },
      );

      final scene = node.mount();
      signal.emit(1);
      edited = true;
      scene.reassemble();
      signal.emit(2);

      expect(log, ['old 1', 'new 2']);
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

  group('keep', () {
    test('runs create once and hands the same value back', () {
      var creates = 0;

      final node = LiveTestNode(
        builder: (node) {
          node.keep(#value, () {
            creates += 1;
            return _A();
          });
        },
      );

      final scene = node.mount();
      scene.reassemble();
      scene.reassemble();

      expect(creates, 1);
    });

    test('preserves a kept child while a plain declaration is replaced', () {
      late Node kept;
      late Node fresh;

      final node = LiveTestNode(
        builder: (node) {
          kept = node.add(node.keep(#kept, () => _A()));
          fresh = node.add(_B());
        },
      );

      final scene = node.mount();
      final firstKept = kept;
      final firstFresh = fresh;

      scene.reassemble();

      expect(kept, same(firstKept));
      expect(firstKept.isMounted, isTrue, reason: 'kept by name, not position');
      expect(fresh, isNot(same(firstFresh)));
    });

    test('replaces the value once its keys stop matching', () {
      var size = 10.0;
      late Node square;

      final node = LiveTestNode(
        builder: (node) {
          square = node.add(node.keep(#square, () => _A(), keys: [size]));
        },
      );

      final scene = node.mount();
      final first = square;

      scene.reassemble();
      expect(square, same(first), reason: 'the keys still match');

      size = 20;
      scene.reassemble();

      expect(square, isNot(same(first)));
      expect(first.isMounted, isFalse, reason: 'what the keys replaced is gone');
    });

    test('replaces a kept value when the name starts building another type', () {
      var swapped = false;
      late Node thing;

      final node = LiveTestNode(
        builder: (node) {
          if (swapped) {
            thing = node.add(node.keep(#thing, _B.new));
          } else {
            thing = node.add(node.keep(#thing, _A.new));
          }
        },
      );

      final scene = node.mount();
      final first = thing;
      expect(first, isA<_A>());

      swapped = true;
      scene.reassemble();

      expect(thing, isA<_B>());
      expect(first.isMounted, isFalse, reason: 'what it replaced is gone');
    });

    test('sweeps a name the new pass stopped declaring', () {
      var keep = true;
      late Node dot;

      final node = LiveTestNode(
        builder: (node) {
          if (!keep) return;
          dot = node.add(node.keep(#dot, () => _A()));
        },
      );

      final scene = node.mount();
      final first = dot;

      keep = false;
      scene.reassemble();

      expect(first.isMounted, isFalse);
      expect(node.children, isEmpty);
    });

    test('a pass that throws part-way sweeps nothing', () {
      var boom = false;
      var creates = 0;
      late Node other;

      final node = LiveTestNode(
        builder: (node) {
          node.add(node.keep(#dot, () => _A()));
          if (boom) throw StateError('mid-edit');

          other = node.add(
            node.keep(#other, () {
              creates += 1;
              return _B();
            }),
          );
        },
      );

      final scene = node.mount();
      final first = other;

      boom = true;
      _reported(() {
        scene.reassemble();
      });

      // The name was never reached, so its value is still kept, and the pass
      // that fixes the error finds it rather than building a second one.
      boom = false;
      scene.reassemble();

      expect(creates, 1);
      expect(other, same(first));
      expect(first.isMounted, isTrue);
    });

    test('asserts when one pass declares the same name twice', () {
      final node = LiveTestNode(
        builder: (node) {
          node.keep(#value, () => _A());
          node.keep(#value, () => _B());
        },
      );

      expect(node.mount, throwsAssertionError);
    });

    test('a kept child owns its own subscriptions', () {
      final signal = Signal0();
      late _Listener child;

      // _Listener subscribes in its constructor, which a pass left current
      // during creation would claim.
      final node = LiveTestNode(
        builder: (node) {
          child = node.add(node.keep(#child, () => _Listener(signal)));
        },
      );

      final scene = node.mount();
      scene.reassemble();
      signal.emit();

      expect(child.heard, 1, reason: 'the parent rebuild did not revoke it');
    });

    test('moves a kept child into the container the new pass built', () {
      late TestNode kid;

      final node = LiveTestNode(
        builder: (node) {
          kid = node.keep(#kid, TestNode.new);
          node.add(Node(children: [kid]));
        },
      );

      final scene = node.mount();
      final first = kid;

      scene.reassemble();

      expect(kid, same(first));
      expect(kid.isMounted, isTrue);
      expect(kid.builds, 2, reason: 'a move remounts');
      expect(node.children.single.children.single, same(kid));
    });

    test('builds a Live child the pass just declared exactly once', () {
      late LiveTestNode child;

      final root = LiveTestNode(
        builder: (node) {
          child = node.add(LiveTestNode());
        },
      );

      final scene = root.mount();
      expect(child.builds, 1);

      scene.reassemble();

      expect(child.builds, 1, reason: 'built by the rebuild that added it, not again by the walk');
    });

    test('reassembles a kept node the pass moved into a fresh container', () {
      late LiveTestNode deep;

      final root = LiveTestNode(
        builder: (node) {
          deep = node.keep(#deep, LiveTestNode.new);
          node.add(Node(children: [deep]));
        },
      );

      final scene = root.mount();
      expect(deep.builds, 1);

      scene.reassemble();

      expect(root.builds, 2);
      expect(deep.builds, 2, reason: 'the walk reached it through the new container');
    });

    group('collections', () {
      test('creates one value per id, and only for the ids it has not seen', () {
        var ids = [1, 2];
        var creates = 0;

        final node = LiveTestNode(
          builder: (node) {
            for (final id in ids) {
              node.add(
                node.keep(#item, () {
                  creates += 1;
                  return _A();
                }, id: id),
              );
            }
          },
        );

        final scene = node.mount();
        expect(creates, 2);

        ids = [1, 2, 3];
        scene.reassemble();

        expect(creates, 3, reason: 'only the new id was built');
        expect(node.children, hasLength(3));
      });

      test('sweeps exactly the id that stopped being declared', () {
        var ids = [1, 2, 3];
        final seen = <int, Node>{};

        final node = LiveTestNode(
          builder: (node) {
            for (final id in ids) {
              seen[id] = node.add(node.keep(#item, () => _A(), id: id));
            }
          },
        );

        final scene = node.mount();
        final before = Map.of(seen);

        ids = [1, 3];
        scene.reassemble();

        expect(before[2]!.isMounted, isFalse);
        expect(before[1]!.isMounted, isTrue);
        expect(before[3]!.isMounted, isTrue);
        expect(node.children, hasLength(2));
      });

      test('keeps every instance across a reorder of the source data', () {
        var ids = [1, 2, 3];
        final seen = <int, Node>{};

        final node = LiveTestNode(
          builder: (node) {
            for (final id in ids) {
              seen[id] = node.add(node.keep(#item, () => _A(), id: id));
            }
          },
        );

        final scene = node.mount();
        final before = Map.of(seen);

        ids = [3, 1, 2];
        scene.reassemble();

        expect(seen[1], same(before[1]));
        expect(seen[2], same(before[2]));
        expect(seen[3], same(before[3]));
      });
    });
  });
}
