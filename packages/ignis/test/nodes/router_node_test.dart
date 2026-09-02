import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/canvas.dart';
import '../support/test_device.dart';
import '../support/test_node.dart';
import '../support/test_transition.dart';

/// A route with a full-screen tap area and a key bind of its own.
final class _Route extends TestNode {
  late TapInput taps;
  int presses = 0;

  _Route({super.name});

  @override
  void build() {
    super.build();
    taps = add(TapInput(shape: .square(100)));

    Ignis.controls.bind((_) {
      presses += 1;
    }, matchers: {const TestEvent()});
  }
}

/// Draws its name onto the debug overlay, so parity walks are observable.
final class _DebugProbe extends Node {
  final String name;
  final List<String> drawn;

  _DebugProbe(this.name, this.drawn);

  @override
  void build() {
    super.build();

    debugDraw((canvas) {
      drawn.add(name);
    });
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Ignis.controls = Controls();
  });

  final canvas = RecordingCanvas();

  (Scene, RouterNode) rig(
    Node initial, {
    TransitionFactory? transition,
    Iterable<Node> hud = const [],
  }) {
    final router = RouterNode(
      initial: initial,
      transition: transition,
      children: hud,
    );

    final scene = Node(children: [router]).mount();
    scene.resize(100, 100);
    scene.update(0);
    return (scene, router);
  }

  group('boot', () {
    test('the initial route is active after the priming update', () {
      final initial = TestNode(name: 'initial');
      final (scene, router) = rig(initial);

      expect(initial.isMounted, isTrue);
      expect(router.top, initial);
      expect(router.stack, [initial]);
      expect(router.isTransitioning, isFalse);

      scene.update(1);
      expect(initial.updates, greaterThan(0));
    });

    test('a re-mount does not duplicate the holder', () {
      final initial = TestNode(name: 'initial');
      final (scene, router) = rig(initial);
      final root = scene.node;

      root.remove(router);
      scene.update(0);
      expect(initial.unmounts, 1);

      root.add(router);
      scene.update(0);
      scene.update(0);

      expect(initial.mounts, 2);
      expect(router.top, initial);
      expect(router.children.length, 1);
    });
  });

  group('commit-at-call', () {
    test('top, stack, and onStackChange flip synchronously', () {
      final initial = TestNode(name: 'initial');
      final (_, router) = rig(initial);
      var changes = 0;
      router.onStackChange(() => changes += 1);

      final next = TestNode(name: 'next');
      router.go(next);

      expect(router.top, next);
      expect(router.stack, [next]);
      expect(changes, 1);
      expect(router.isTransitioning, isTrue);
      expect(next.isMounted, isFalse, reason: 'pixels settle over the next frames');
    });

    test('isTransitioning holds until the navigation settles', () {
      final (scene, router) = rig(
        TestNode(),
        transition: (to, from) => CurtainTransitionEffect(to, from, duration: 1),
      );

      router.go(TestNode());
      scene.update(0.5);
      expect(router.isTransitioning, isTrue);

      scene.update(0.6);
      expect(router.isTransitioning, isTrue, reason: 'the router settles on its next tick');

      scene.update(0);
      expect(router.isTransitioning, isFalse);
    });
  });

  group('return values', () {
    test('push completes with the value pop is given', () async {
      final (scene, router) = rig(TestNode());

      final answer = router.push<bool>(TestNode(name: 'confirm'));
      scene.update(0);
      scene.update(0);

      router.pop(result: true);
      expect(await answer, isTrue);
    });

    test('pop without a result completes with null', () async {
      final (scene, router) = rig(TestNode());

      final answer = router.push<bool>(TestNode());
      scene.update(0);
      scene.update(0);

      router.pop();
      expect(await answer, isNull);
    });

    test('go over pushed routes completes their futures with null', () async {
      final (scene, router) = rig(TestNode());

      final answer = router.push<bool>(TestNode());
      scene.update(0);
      scene.update(0);

      router.go(TestNode());
      expect(await answer, isNull);
    });

    test('unmounting the router completes outstanding futures with null', () async {
      final (scene, router) = rig(TestNode());

      final answer = router.push<bool>(TestNode());
      scene.update(0);
      scene.update(0);

      scene.node.remove(router);
      scene.update(0);
      expect(await answer, isNull);
    });

    test('a mismatched result type surfaces at the awaiting site', () async {
      final (scene, router) = rig(TestNode());

      final answer = router.push<bool>(TestNode());
      scene.update(0);
      scene.update(0);

      router.pop(result: 'not a bool');
      await expectLater(answer, throwsA(isA<TypeError>()));
    });
  });

  group('backdrops', () {
    test('frozen stops updates at the commit, keeps painting, blocks input', () {
      final game = _Route(name: 'game');
      final (scene, router) = rig(game);
      scene.update(1);
      final ticked = game.updates;

      final menu = _Route(name: 'menu');
      router.push(menu);
      scene.update(1);
      scene.update(1);
      scene.update(1);
      expect(game.updates, ticked, reason: 'frozen at the commit');

      final painted = game.renders;
      scene.render(canvas);
      expect(game.renders, painted + 1, reason: 'still painting');

      expect(scene.node.hitTest(.all(50)).whereType<TapInput>().firstOrNull, menu.taps);

      Ignis.controls.dispatch(const TestEvent());
      expect(menu.presses, 1);
      expect(game.presses, 0);

      router.pop();
      scene.update(0);
      scene.update(1);
      expect(game.updates, greaterThan(ticked), reason: 'pop resumes updating');
    });

    test('live keeps the world updating and painting, input still blocked', () {
      final game = _Route(name: 'game');
      final (scene, router) = rig(game);
      scene.update(1);
      final ticked = game.updates;

      router.push(_Route(name: 'confirm'), backdrop: .live);
      scene.update(1);
      scene.update(1);
      expect(game.updates, greaterThan(ticked), reason: 'the router drives it');

      final painted = game.renders;
      scene.render(canvas);
      expect(game.renders, painted + 1);

      expect(scene.node.hitTest(.all(50)).whereType<TapInput>().firstOrNull, isNot(game.taps));
      Ignis.controls.dispatch(const TestEvent());
      expect(game.presses, 0);
    });

    test('a disabled child inside a live backdrop stays un-ticked', () {
      final game = TestNode(name: 'game');
      final (scene, router) = rig(game);

      router.push(TestNode(name: 'confirm'), backdrop: .live);
      scene.update(1);
      final ticked = game.updates;

      game.enabled = false;
      scene.update(1);
      expect(game.updates, ticked);
    });

    test('hidden paints through the transition, then not at all, until the pop', () {
      final game = TestNode(name: 'game');
      final (scene, router) = rig(
        game,
        transition: (to, from) => CurtainTransitionEffect(to, from, duration: 1),
      );

      router.push(TestNode(name: 'menu'), backdrop: .hidden);
      scene.update(0.5);
      final painted = game.renders;
      scene.render(canvas);
      expect(game.renders, painted + 1, reason: 'still the transition\'s from');

      scene.update(0.6);
      scene.update(0);
      scene.update(0);
      final settled = game.renders;
      scene.render(canvas);
      expect(game.renders, settled, reason: 'hidden once settled');

      router.pop();
      scene.update(0.5);
      scene.render(canvas);
      expect(game.renders, settled + 1, reason: 'revealed by the pop transition');
    });

    test('backdrops compose locally, and re-derive on every pop', () {
      final game = TestNode(name: 'game');
      final dialog = TestNode(name: 'dialog');
      final confirm = TestNode(name: 'confirm');
      final (scene, router) = rig(game);

      router.push(dialog, backdrop: .live);
      scene.update(1);
      scene.update(1);

      router.push(confirm, backdrop: .frozen);
      scene.update(1);
      scene.update(1);
      final gameTicks = game.updates;
      final dialogTicks = dialog.updates;
      final confirmTicks = confirm.updates;

      scene.update(1);
      expect(game.updates, gameTicks + 1, reason: 'live under the dialog');
      expect(dialog.updates, dialogTicks, reason: 'frozen under the confirm');
      expect(confirm.updates, confirmTicks + 1, reason: 'the top is active');

      router.pop();
      scene.update(0);
      scene.update(1);
      expect(dialog.updates, greaterThan(dialogTicks), reason: 'active again');
      expect(game.updates, greaterThan(gameTicks + 1), reason: 'still live');
    });
  });

  test('no steady-state blocking: outside controls keep working under a push', () {
    final game = _Route(name: 'game');
    final (scene, router) = rig(game);
    var toggles = 0;

    final unbind = Ignis.controls.bind((_) {
      toggles += 1;
    }, matchers: {const TestEvent()});

    addTearDown(unbind);

    router.push(TestNode(name: 'menu'));
    scene.update(0);
    scene.update(0);
    scene.update(0);

    Ignis.controls.dispatch(const TestEvent());
    expect(toggles, 1, reason: 'no barrier exists in steady state');
    expect(game.presses, 0, reason: 'the backdrop\'s controls stay muted');
  });

  group('rendering', () {
    test('painted backdrops render below the active route, HUD above both', () {
      final log = TestLog();
      final game = TestNode(name: 'game', log: log);
      final hud = TestNode(name: 'hud', log: log);
      final (scene, router) = rig(game, hud: [hud]);

      router.push(TestNode(name: 'menu', log: log));
      scene.update(0);
      scene.update(0);
      scene.update(0);

      log.renders.clear();
      scene.render(canvas);
      expect(log.renders, ['game', 'menu', 'hud']);
    });

    test('a hidden backdrop is absent from the walk, and debugRender agrees', () {
      final debugged = <String>[];
      final game = TestNode(name: 'game', children: [_DebugProbe('game', debugged)]);
      final menu = TestNode(name: 'menu', children: [_DebugProbe('menu', debugged)]);
      final (scene, router) = rig(game);

      router.push(menu, backdrop: .hidden);
      scene.update(0);
      scene.update(0);
      scene.update(0);

      final log = TestLog();
      game.log = log;
      menu.log = log;
      scene.render(canvas);
      expect(log.renders, ['menu']);

      debugged.clear();
      scene.node.debugRender(canvas);
      expect(debugged, ['menu']);
    });
  });

  test('a null transition cuts: swap next frame, settle the frame after', () {
    final initial = TestNode(name: 'initial');
    final (scene, router) = rig(initial);
    final next = TestNode(name: 'next');

    router.go(next);
    scene.update(0);
    expect(next.isMounted, isTrue);
    expect(next.updates, 0, reason: 'revealed this frame, ticking from the next');

    scene.update(0);
    expect(router.isTransitioning, isFalse);

    scene.update(0);
    expect(initial.unmounts, 1);
    expect(router.children.length, 1);
  });

  group('input during a navigation', () {
    test('the barrier eats pointers, hovers, and keys until settle', () {
      final game = _Route(name: 'game');
      final (scene, router) = rig(
        game,
        transition: (to, from) => CurtainTransitionEffect(to, from, duration: 1),
      );

      final menu = _Route(name: 'menu');
      router.go(menu);
      scene.update(0.5);

      final claimed = scene.node.hitTest(.all(50)).whereType<InputNode>().first;
      expect(claimed, isA<HoverInput>());
      expect(claimed, isNot(menu.taps));

      expect(Ignis.controls.dispatch(const TestEvent()), isTrue);
      expect(menu.presses, 0);
      expect(game.presses, 0);

      scene.update(0.6);
      scene.update(0);
      scene.update(0);
      Ignis.controls.dispatch(const TestEvent());
      expect(menu.presses, 1);
    });

    test('a control bound in the transition\'s build outranks the barrier', () {
      var skips = 0;
      final (scene, router) = rig(_Route(name: 'game'));

      router.go(
        _Route(name: 'menu'),
        transition: (to, from) => TestTransition(
          to,
          from,
          onBuild: (_) {
            Ignis.controls.bind((_) {
              skips += 1;
            }, matchers: {const TestEvent()});
          },
        ),
      );

      scene.update(0.5);

      Ignis.controls.dispatch(const TestEvent());
      expect(skips, 1);
    });
  });

  group('interleaved navigations', () {
    test('a same-frame double go never mounts the first incoming route', () {
      final initial = TestNode(name: 'initial');
      final (scene, router) = rig(initial);
      final b = TestNode(name: 'b');
      final c = TestNode(name: 'c');

      router.go(b);
      router.go(c);
      scene.update(0);
      scene.update(0);
      scene.update(0);

      expect(b.mounts, 0);
      expect(b.unmounts, 0);
      expect(router.top, c);
      expect(c.isMounted, isTrue);
      expect(initial.unmounts, 1);
      expect(router.children.length, 1);
    });

    test('a push popped in the same frame answers without ever mounting', () async {
      final initial = TestNode(name: 'initial');
      final (scene, router) = rig(initial);
      final menu = TestNode(name: 'menu');

      final answer = router.push<bool>(menu);
      router.pop(result: true);
      scene.update(0);
      scene.update(0);
      scene.update(0);

      expect(await answer, isTrue);
      expect(menu.mounts, 0);
      expect(router.top, initial);
      expect(router.isTransitioning, isFalse);
      expect(router.children.length, 1);
    });

    test('a go mid-transition force-finishes the last navigation first', () {
      final initial = TestNode(name: 'initial');
      final (scene, router) = rig(
        initial,
        transition: (to, from) => CurtainTransitionEffect(to, from, duration: 1),
      );
      final b = TestNode(name: 'b');
      final c = TestNode(name: 'c');

      router.go(b);
      scene.update(0.3);
      expect(b.isMounted, isTrue);

      router.go(c);
      expect(router.top, c);
      expect(router.isTransitioning, isTrue);

      scene.update(0.5);
      scene.update(0.6);
      scene.update(0);
      scene.update(0);

      expect(b.unmounts, 1);
      expect(initial.unmounts, 1);
      expect(c.isMounted, isTrue);
      expect(router.isTransitioning, isFalse);
      expect(router.children.length, 1);
    });
  });

  test('popping a stack of one throws', () {
    final (_, router) = rig(TestNode());

    expect(() => router.pop(), throwsStateError);
  });

  group('DI', () {
    test('read resolves from a deep descendant', () {
      final probe = Node();
      final (_, router) = rig(
        TestNode(
          children: [
            Node(children: [probe]),
          ],
        ),
      );

      expect(probe.read<RouterNode>(), router);
    });

    test('nested routers resolve to the nearest', () {
      final probe = Node();
      final inner = RouterNode(initial: TestNode(children: [probe]));
      final (scene, outer) = rig(TestNode(children: [inner]));
      scene.update(0);
      scene.update(0);

      expect(probe.read<RouterNode>(), inner);
      expect(inner.read<RouterNode>(), inner);
      expect(outer.read<RouterNode>(), outer);
    });
  });

  group('reassemble', () {
    test('mid-route: holders stand, Live content rebuilds in place', () {
      final live = LiveTestNode(name: 'game');
      final (scene, router) = rig(live);

      scene.reassemble();

      expect(live.builds, 2);
      expect(live.unmounts, 0);
      expect(router.children.length, 1);
      expect(router.top, live);
    });

    test('mid-navigation: the transition stands, and plays out', () {
      TestTransition? transition;
      final initial = TestNode(name: 'initial');
      final (scene, router) = rig(initial);
      final next = TestNode(name: 'next');

      router.go(next, transition: (to, from) => transition = TestTransition(to, from));
      scene.update(0.3);
      expect(transition!.builds, 1);

      scene.reassemble();
      expect(transition!.builds, 1);
      expect(router.children.length, 4, reason: 'two holders, the barrier, and the effect');

      scene.update(0.8);
      scene.update(0);
      scene.update(0);

      expect(router.isTransitioning, isFalse);
      expect(initial.unmounts, 1);
      expect(next.isMounted, isTrue);
      expect(router.children.length, 1);
    });
  });
}
