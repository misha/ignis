import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/canvas.dart';
import '../../support/test_backdrop.dart';
import '../../support/test_node.dart';
import '../../support/test_transition.dart';

void main() {
  final canvas = RecordingCanvas();

  group('the stack', () {
    test('is the route children, bottom to top', () {
      final a = RouteNode();
      final b = RouteNode();
      final router = RouterNode(children: [a, b]);

      router.mount();
      expect(router.routes, [a, b]);
      expect(router.top, b);
    });

    test('paints bottom to top', () {
      final log = TestLog();

      final router = RouterNode(
        children: [
          RouteNode(
            children: [TestNode(name: 'a', log: log)],
          ),
          RouteNode(
            children: [TestNode(name: 'b', log: log)],
          ),
        ],
      );

      router.mount().render(canvas);
      expect(log.renders, ['a', 'b']);
    });

    test('leaves a covered route painting but not ticking', () {
      final a = TestNode(name: 'a');
      final b = TestNode(name: 'b');

      final scene = RouterNode(
        children: [
          RouteNode(children: [a]),
          RouteNode(children: [b]),
        ],
      ).mount();

      scene.update(0);
      scene.render(canvas);

      expect(a.updates, 0);
      expect(a.renders, 1);
      expect(b.updates, 1);
      expect(b.renders, 1);
    });

    test('lets a covered route keep running under a live backdrop', () {
      final a = TestNode(name: 'a');

      final scene = RouterNode(
        children: [
          RouteNode(children: [a]),
          RouteNode(backdrop: const .live()),
        ],
      ).mount();

      scene.update(0);
      expect(a.updates, 1);
    });

    test('stops a covered route painting under a hidden backdrop', () {
      final a = TestNode(name: 'a');

      final scene = RouterNode(
        children: [
          RouteNode(children: [a]),
          RouteNode(backdrop: const .hidden()),
        ],
      ).mount();

      scene.update(0);
      scene.render(canvas);
      expect(a.renders, 0);
    });

    test('stops input at the top', () {
      final tapA = TapInput(shape: .square(100));
      final tapB = TapInput(shape: .square(100));

      final router = RouterNode(
        children: [
          RouteNode(children: [tapA]),
          RouteNode(children: [tapB]),
        ],
      );

      router.mount().update(0);
      final hits = router.hitTest(Vector2.all(10)).toList();

      expect(hits, contains(tapB));
      expect(hits, isNot(contains(tapA)));
    });

    test('takes the scene as its region with nothing above', () {
      final route = RouteNode();
      RouterNode(children: [route]).mount().resize(100, 100);

      expect(route.size, Vector2.all(100));
    });

    test('takes the shape in effect above its router node', () {
      final route = RouteNode();

      SpatialNode(
        shape: .rectangle(.new(60, 40)),
        children: [
          RouterNode(children: [route]),
        ],
      ).mount();

      expect(route.size, Vector2(60, 40));
    });

    test('takes its own shape over the one above it', () {
      final route = RouteNode();

      SpatialNode(
        shape: .rectangle(.new(60, 40)),
        children: [
          RouterNode(shape: .rectangle(.new(30, 20)), children: [route]),
        ],
      ).mount();

      expect(route.size, Vector2(30, 20));
    });
  });

  group('push', () {
    test('begins at the call, but holds until the route is in the tree', () {
      final transition = TestTransition();
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();
      final pushed = RouteNode(transition: transition);

      router.push(pushed);
      expect(router.isTransitioning, isTrue);
      expect(router.routes, isNot(contains(pushed)), reason: 'the add is still queued');

      scene.update(0);
      expect(router.top, pushed);
      expect(transition.applies, [0]);
    });

    test('poses only the incoming side', () {
      final covered = RouteNode();
      final router = RouterNode(children: [covered]);
      final scene = router.mount();
      scene.resize(100, 100);
      final pushed = RouteNode(transition: SlideTransition());

      router.push(pushed);
      scene.update(0);
      scene.update(0.5);

      expect(pushed.position.y, 50);
      expect(covered.position.y, 0);
      expect(covered.opacity, 1);
    });

    test('poses its backdrop, and a pop plays it back', () {
      final backdrop = TestBackdrop();
      final covered = RouteNode();
      final router = RouterNode(children: [covered]);
      final scene = router.mount();

      router.push(RouteNode(backdrop: backdrop, transition: TestTransition()));
      scene.update(0);
      scene.update(0.5);
      scene.update(0.5);

      router.pop();
      scene.update(0.5);

      expect(
        backdrop.applies,
        [0, 0.5, 1, 0.5],
        reason: 'the push finishes at 1, and the pop plays back from there',
      );
    });

    test('asserts on a route already on the stack', () {
      final route = RouteNode();
      final router = RouterNode(children: [RouteNode(), route]);
      router.mount();

      expect(() => router.push(route), throwsA(isA<AssertionError>()));
    });

    test('completes with what its pop carries', () async {
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();

      final result = router.push<String>(RouteNode());
      scene.update(0);
      router.pop('carried');

      expect(await result, 'carried');
    });

    test('completes with null on a bare pop', () async {
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();

      final result = router.push<String>(RouteNode());
      scene.update(0);
      router.pop();

      expect(await result, isNull);
    });

    test('completes with null when a later navigation drops it', () async {
      final router = RouterNode(children: [RouteNode()]);
      router.mount();

      final dropped = router.push<String>(RouteNode());
      router.go(RouteNode());

      expect(await dropped, isNull);
    });

    test("carries a later pop's result when pushed again while being popped", () async {
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();
      final route = RouteNode(transition: TestTransition());

      router.push(route);
      scene.update(0);
      scene.update(1);
      router.pop();

      final result = router.push<String>(route);
      scene.update(0);
      scene.update(1);
      router.pop('again');

      expect(await result, 'again');
    });
  });

  group('pop', () {
    test('takes the route out of the tree', () {
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();
      final pushed = RouteNode(transition: TestTransition());

      router.push(pushed);
      scene.update(0);
      scene.update(1);

      router.pop();
      scene.update(1);
      scene.update(0);

      expect(pushed.isMounted, isFalse);
      expect(router.routes, isNot(contains(pushed)));
    });

    test('wakes the route beneath', () {
      final a = TestNode(name: 'a');
      final router = RouterNode(
        children: [
          RouteNode(children: [a]),
        ],
      );

      final scene = router.mount();
      router.push(RouteNode(transition: TestTransition()));
      scene.update(0);
      scene.update(1);

      final covered = a.updates;
      router.pop();
      scene.update(1);
      scene.update(0);

      expect(a.updates, greaterThan(covered));
    });

    test('reverses the push still in flight rather than settling it', () {
      final transition = TestTransition();
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();

      router.push(RouteNode(transition: transition));
      scene.update(0);
      scene.update(0.3);

      router.pop();
      scene.update(0.1);
      expect(transition.applies, [0, 0.3, closeTo(0.2, 1e-9)]);
    });

    test('takes back a push still arriving', () async {
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();
      final pushed = RouteNode();

      final result = router.push<String>(pushed);
      router.pop('carried');
      scene.update(0);

      expect(await result, 'carried');
      expect(pushed.isMounted, isFalse);
    });

    test('settles the running pop, then pops the next', () {
      final transition = TestTransition();
      final c = RouteNode(transition: TestTransition());

      final router = RouterNode(
        children: [
          RouteNode(),
          RouteNode(transition: transition),
          c,
        ],
      );

      final scene = router.mount();
      router.pop();
      scene.update(0.3);

      router.pop();
      scene.update(0.5);

      expect(c.isMounted, isFalse);
      expect(transition.applies, [0.5], reason: 'the next pop plays back from 1');
    });

    test('throws during a go', () {
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();

      router.go(RouteNode(), transition: TestTransition());
      scene.update(0);

      expect(router.pop, throwsStateError);
    });

    test('throws while a go is arriving', () {
      final router = RouterNode(children: [RouteNode()]);
      router.mount();

      router.go(RouteNode());
      expect(router.pop, throwsStateError);
    });

    test('throws on a stack of one', () {
      final router = RouterNode(children: [RouteNode()]);
      router.mount();

      expect(router.pop, throwsStateError);
    });

    test('completes once the navigation settles', () async {
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();

      router.push(RouteNode(transition: TestTransition()));
      scene.update(0);
      scene.update(1);

      var settled = false;
      router.pop().then((_) => settled = true);

      scene.update(1);
      await pumpEventQueue();
      expect(settled, isTrue);
    });
  });

  group('go', () {
    test('takes everything beneath the incoming route off the stack', () {
      final a = RouteNode();
      final b = RouteNode();
      final router = RouterNode(children: [a, b]);
      final scene = router.mount();
      final c = RouteNode();

      router.go(c, transition: TestTransition());
      scene.update(0);
      scene.update(1);
      scene.update(0);

      expect(router.routes, [c]);
      expect(a.isMounted, isFalse);
      expect(b.isMounted, isFalse);
    });

    test('runs both sides through its transition', () {
      final transition = TestTransition();
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();

      router.go(RouteNode(), transition: transition);
      scene.update(0);
      scene.update(0.25);
      scene.update(0.25);

      expect(transition.applies, [0, 0.25, 0.5]);
    });

    test('plays the transition the incoming route carries', () {
      final transition = TestTransition();
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();

      router.go(RouteNode(transition: transition));
      scene.update(0);
      scene.update(0.25);

      expect(transition.applies, [0, 0.25]);
    });

    test('names a transition over the one the route carries', () {
      final carried = TestTransition();
      final named = TestTransition();
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();

      router.go(RouteNode(transition: carried), transition: named);
      scene.update(0);
      scene.update(0.25);

      expect(named.applies, [0, 0.25]);
      expect(carried.applies, isEmpty);
    });

    test('leaves the outgoing side running, but deaf', () {
      final outgoing = RouteNode();
      final router = RouterNode(children: [outgoing]);
      final scene = router.mount();
      final incoming = RouteNode();

      router.go(incoming, transition: TestTransition());
      scene.update(0);

      expect(outgoing.activity, Activity.update | Activity.render);
      expect(incoming.activity, Activity.all);
    });

    test('honors the activities its transition names for each side', () {
      final outgoing = RouteNode();
      final router = RouterNode(children: [outgoing]);
      final scene = router.mount();
      final incoming = RouteNode();

      router.go(
        incoming,
        transition: TestTransition(incoming: Activity.render, outgoing: Activity.none),
      );

      scene.update(0);
      expect(outgoing.activity, Activity.none);
      expect(incoming.activity, Activity.render);
    });

    test('going back to the departed route mid-swap settles, then swaps again', () {
      final red = RouteNode();
      final router = RouterNode(children: [red]);
      final scene = router.mount();
      final green = RouteNode();

      router.go(green, transition: TestTransition());
      scene.update(0);
      scene.update(0.3);

      router.go(red, transition: TestTransition());
      scene.update(0);
      scene.update(1);
      scene.update(0);

      expect(router.routes, [red]);
      expect(green.isMounted, isFalse);
    });

    test('settles the running navigation before starting', () {
      final a = RouteNode();
      final router = RouterNode(children: [a]);
      final scene = router.mount();
      final c = RouteNode();

      router.go(RouteNode(), transition: TestTransition());
      scene.update(0);
      scene.update(0.3);

      router.go(c, transition: TestTransition());
      scene.update(0);

      expect(a.isMounted, isFalse, reason: 'the first swap was settled at the call');
      expect(router.top, c);
    });

    test('returns both sides to rest at settle', () {
      final outgoing = RouteNode();
      final router = RouterNode(children: [outgoing]);
      final scene = router.mount();
      final incoming = RouteNode();

      router.go(incoming, transition: FadeTransition(crossFade: true));
      scene.update(0);
      scene.update(0.5);
      expect(incoming.opacity, 0.5);

      scene.update(0.5);
      expect(incoming.opacity, 1);
      expect(outgoing.opacity, 1);
    });

    test('builds a route again when it is returned to', () {
      var builds = 0;
      final a = RouteNode(children: [TestNode(builder: (_) => builds += 1)]);
      final router = RouterNode(children: [a]);
      final scene = router.mount();
      expect(builds, 1);

      router.go(RouteNode(), transition: TestTransition());
      scene.update(0);
      scene.update(1);
      scene.update(0);
      expect(a.isMounted, isFalse);

      router.go(a, transition: TestTransition());
      scene.update(0);
      expect(builds, 2);
    });
  });

  group('chrome', () {
    test('paints above the stack, after both sides', () {
      final log = TestLog();
      final chrome = TestNode(name: 'chrome', log: log);

      final router = RouterNode(
        children: [
          RouteNode(
            children: [TestNode(name: 'a', log: log)],
          ),
        ],
      );

      final scene = router.mount();

      router.go(
        RouteNode(
          children: [TestNode(name: 'b', log: log)],
        ),
        transition: TestTransition(chrome: chrome),
      );

      scene.update(0);
      scene.update(0.5);
      scene.render(canvas);
      expect(log.renders, ['a', 'b', 'chrome']);
    });

    test('comes back for a second navigation through the same transition', () {
      final log = TestLog();
      final chrome = TestNode(name: 'chrome', log: log);
      final transition = TestTransition(chrome: chrome);
      final router = RouterNode(transition: transition, children: [RouteNode()]);
      final scene = router.mount();

      router.go(RouteNode());
      scene.update(0);
      scene.update(1);
      scene.update(0);

      router.go(RouteNode());
      scene.update(0);
      scene.update(0.5);
      scene.render(RecordingCanvas());

      expect(log.renders, ['chrome']);
    });

    test('stays above the stack across repeated swaps', () {
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();

      for (var swap = 0; swap < 5; swap += 1) {
        final chrome = Node();
        final incoming = RouteNode(transition: TestTransition(chrome: chrome));

        router.go(incoming);
        scene.update(0);
        expect(chrome.priority, greaterThan(incoming.priority), reason: 'swap $swap');

        scene.update(1);
      }
    });

    test('paints its last frame at settle, then leaves the tree', () {
      final log = TestLog();
      final chrome = TestNode(name: 'chrome', log: log);
      final router = RouterNode(children: [RouteNode()]);
      final scene = router.mount();

      router.go(RouteNode(), transition: TestTransition(chrome: chrome));
      scene.update(0);
      scene.update(1);
      expect(router.isTransitioning, isFalse);

      scene.render(canvas);
      expect(log.renders, ['chrome'], reason: 'the settling frame finishes the arc');

      scene.update(0);
      expect(router.children, isNot(contains(chrome)));
    });
  });
}
