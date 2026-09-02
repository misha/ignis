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

    test('a build that throws on a live add throws out of update', () {
      final root = LiveTestNode(builder: (_) {});
      final scene = root.mount();
      root.add(LiveTestNode(builder: (_) => throw StateError('no ancestor')));

      expect(() => scene.update(0), throwsStateError);
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

  group('reassembly', () {
    test('rebuilds every node that mixes in Live', () {
      final child = LiveTestNode(builder: (_) {});
      final parent = LiveTestNode(builder: (node) => node.add(child));
      final scene = parent.mount()..update(0);

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
      final node = LiveTestNode(builder: (n) => n.add(_Sized(size)));
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

      final node = LiveTestNode(
        builder: (n) {
          given = _A();
          returned = n.add(given!);
        },
      );

      final scene = node.mount()..update(0);
      expect(returned, same(given));

      scene.reassemble();
      scene.update(0);

      expect(returned, same(given), reason: 'the fresh one, never a standing one');
      expect(node.children.single, same(given));
    });

    test('destroys the children the previous build declared', () {
      final node = LiveTestNode(builder: (n) => n.add(_A()));
      final scene = node.mount()..update(0);
      final first = node.children.single;

      scene.reassemble();
      scene.update(0);

      expect(first.isMounted, isFalse);
      expect(node.children.single, isNot(same(first)));
    });

    test('a child that stops being declared does not come back', () {
      var declared = true;

      final node = LiveTestNode(
        builder: (n) {
          if (declared) n.add(_A());
        },
      );

      final scene = node.mount()..update(0);
      expect(node.children, hasLength(1));

      declared = false;
      scene.reassemble();
      scene.update(0);

      expect(node.children, isEmpty);
    });

    test('leaves imperative additions alone', () {
      final node = LiveTestNode(builder: (n) => n.add(_A()));
      final scene = node.mount()..update(0);
      final spawned = node.add(_B());
      scene.update(0);

      scene.reassemble();
      scene.update(0);

      expect(spawned.isMounted, isTrue, reason: 'no build declared it');
      expect(node.children, hasLength(2));
    });

    test('preserves a child the new build declared again', () {
      final held = TestNode();
      final node = LiveTestNode(builder: (n) => n.add(held));
      final scene = node.mount()..update(0);

      expect(held.builds, 1);

      scene.reassemble();
      scene.update(0);

      expect(node.children.single, same(held));
      expect(held.isMounted, isTrue, reason: 'it never left the tree');
      expect(held.builds, 1, reason: 'a node without Live holds its body');
    });

    test('rebuilds queued before a flush settle to one generation', () {
      final node = LiveTestNode(builder: (n) => n.add(_A()));
      final scene = node.mount()..update(0);

      scene.reassemble();
      scene.reassemble();
      scene.update(0);

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

    test('onMount subscribed in build hears the mount that ran it', () {
      var mounted = 0;
      final node = LiveTestNode(builder: (node) => node.onMount(() => mounted += 1));

      node.mount();

      expect(mounted, 1);
    });

    test('onUnmount subscribed in build fires once, at unmount', () {
      var unmounted = 0;
      final node = LiveTestNode(builder: (node) => node.onUnmount(() => unmounted += 1));
      final scene = node.mount();

      scene.reassemble();
      scene.destroy();

      expect(unmounted, 1);
    });

    test('a rebuild does not report the unmount it causes', () {
      var keep = true;
      var unmounted = 0;

      final node = LiveTestNode(
        builder: (node) {
          if (!keep) return;
          final child = Node();
          node.add(child);
          child.onUnmount(() => unmounted += 1);
        },
      );

      final scene = node.mount();
      scene.update(0);

      keep = false;
      scene.reassemble();
      scene.update(0);

      expect(node.children, isEmpty, reason: 'the child did leave');

      expect(unmounted, 0, reason: 'a reassembly is not an unmount');
    });

    test('onSceneResize fires again for the handler a rebuild installed', () {
      final scene = Node().mount()..resize(100, 80);
      final sizes = <Vector2>[];
      final node = LiveTestNode(builder: (n) => n.onSceneResize(sizes.add));

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
      final node = LiveTestNode(builder: (node) => node.onSceneResize((size) => heard = size));

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

      final scene = node.mount()..update(0);
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

      final scene = node.mount()..update(0);
      final firstKept = kept;
      final firstFresh = fresh;

      scene.reassemble();
      scene.update(0);

      expect(kept, same(firstKept));
      expect(firstKept.isMounted, isTrue, reason: 'a name is not a slot');
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

      final scene = node.mount()..update(0);
      final first = square;

      scene.reassemble();
      scene.update(0);
      expect(square, same(first), reason: 'the keys still match');

      size = 20;
      scene.reassemble();
      scene.update(0);

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

      final scene = node.mount()..update(0);
      final first = thing;
      expect(first, isA<_A>());

      swapped = true;
      scene.reassemble();
      scene.update(0);

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

      final scene = node.mount()..update(0);
      final first = dot;

      keep = false;
      scene.reassemble();
      scene.update(0);

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

      final scene = node.mount()..update(0);
      final first = other;

      boom = true;
      _reported(() {
        scene.reassemble();
        scene.update(0);
      });

      // The name was never reached, so its value is still kept, and the pass
      // that fixes the error finds it rather than building a second one.
      boom = false;
      scene.reassemble();
      scene.update(0);

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

    test('runs create outside the pass, so the child owns its own subscriptions', () {
      late TestNode child;

      // TestNode watches its own onUnmount from its constructor, which is
      // where ownership goes wrong if a pass is left current during creation.
      final node = LiveTestNode(
        builder: (node) {
          child = node.add(node.keep(#child, TestNode.new));
        },
      );

      final scene = node.mount()..update(0);
      scene.reassemble();
      scene.update(0);
      scene.destroy();

      expect(child.unmounts, 1, reason: 'the parent rebuild did not revoke it');
    });

    test('moves a kept child into the container the new pass built', () {
      late TestNode kid;

      final node = LiveTestNode(
        builder: (node) {
          kid = node.keep(#kid, TestNode.new);
          node.add(Node(children: [kid]));
        },
      );

      final scene = node.mount()..update(0);
      final first = kid;

      scene.reassemble();
      scene.update(0);

      expect(kid, same(first));
      expect(kid.isMounted, isTrue, reason: 'a move never unmounts it');
      expect(kid.builds, 1, reason: 'and never rebuilds it');
      expect(node.children.single.children.single, same(kid));
    });

    test('builds a Live child the pass just declared exactly once', () {
      late LiveTestNode child;

      final root = LiveTestNode(
        builder: (node) {
          child = node.add(LiveTestNode());
        },
      );

      final scene = root.mount()..update(0);
      expect(child.builds, 1);

      scene.reassemble();
      scene.update(0);

      expect(child.builds, 1, reason: 'mounted by the flush, not built again by the walk');
    });

    test('reassembles a kept node the pass moved into a fresh container', () {
      late LiveTestNode deep;

      final root = LiveTestNode(
        builder: (node) {
          deep = node.keep(#deep, LiveTestNode.new);
          node.add(Node(children: [deep]));
        },
      );

      final scene = root.mount()..update(0);
      expect(deep.builds, 1);

      scene.reassemble();
      scene.update(0);

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

        final scene = node.mount()..update(0);
        expect(creates, 2);

        ids = [1, 2, 3];
        scene.reassemble();
        scene.update(0);

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

        final scene = node.mount()..update(0);
        final before = Map.of(seen);

        ids = [1, 3];
        scene.reassemble();
        scene.update(0);

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

        final scene = node.mount()..update(0);
        final before = Map.of(seen);

        ids = [3, 1, 2];
        scene.reassemble();
        scene.update(0);

        expect(seen[1], same(before[1]));
        expect(seen[2], same(before[2]));
        expect(seen[3], same(before[3]));
      });
    });
  });
}
