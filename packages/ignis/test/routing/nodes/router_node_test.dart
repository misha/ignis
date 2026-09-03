import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../../support/canvas.dart';
import '../../support/test_node.dart';
import '../../support/test_transition.dart';

void main() {
  final canvas = RecordingCanvas();

  test('the top of the router shows', () {
    final a = TestNode(name: 'a');
    final b = TestNode(name: 'b');

    final host = RouterNode(
      router: Router(top: 'b'),
      children: [
        RouteNode(name: 'a', children: [a]),
        RouteNode(name: 'b', children: [b]),
      ],
    );

    final scene = host.mount();
    scene.render(canvas);
    expect(a.renders, 0);
    expect(b.renders, 1);
  });

  test('a route that mounts late registers', () {
    final router = Router<String>();
    final joined = TestNode(name: 'late');

    final host = RouterNode(
      router: router,
      children: [
        RouteNode(name: 'a'),
        RouteNode(name: 'b'),
      ],
    );

    final scene = host.mount();
    host.add(RouteNode(name: 'c', children: [joined]));
    scene.update(0);

    scene.render(canvas);
    expect(joined.renders, 0);

    router.go('c');
    scene.update(0);

    scene.render(canvas);
    expect(joined.renders, 1);
  });

  test('a detached route unregisters', () {
    final router = Router<String>();
    final b = RouteNode(name: 'b');

    final host = RouterNode(
      router: router,
      children: [
        RouteNode(name: 'a'),
        b,
      ],
    );

    final scene = host.mount();
    host.remove(b);
    scene.update(0);
    expect(() => router.go('b'), throwsA(isA<AssertionError>()));
  });

  test('a router node without a router makes its own', () {
    final host = RouterNode<String>(
      children: [
        RouteNode(name: 'a'),
        RouteNode(name: 'b'),
      ],
    );

    host.mount();
    expect(host.router.top, 'a');
  });

  test('a route reads its router', () {
    final router = Router<String>();
    Router<String>? read;

    RouterNode(
      router: router,
      children: [
        RouteNode(
          name: 'a',
          children: [
            TestNode(
              builder: (node) {
                read = node.read<Router<String>>();
              },
            ),
          ],
        ),
      ],
    ).mount();

    expect(read, same(router));
  });

  test('a route takes the scene as its region with nothing above', () {
    final route = RouteNode(name: 'a');
    final scene = RouterNode(router: Router<String>(), children: [route]).mount();
    scene.resize(100, 100);

    expect(route.size, Vector2.all(100));
  });

  test('a route takes the shape in effect above its router node', () {
    final route = RouteNode(name: 'a');

    SpatialNode(
      shape: .rectangle(.new(60, 40)),
      children: [
        RouterNode<String>(
          router: Router(),
          children: [route],
        ),
      ],
    ).mount();

    expect(route.size, Vector2(60, 40));
  });

  test('a swap paints the outgoing side, the incoming side, then the chrome', () {
    final router = Router<String>();
    final log = TestLog();
    final chrome = TestNode(name: 'chrome', log: log);

    final scene = RouterNode(
      router: router,
      children: [
        RouteNode(
          name: 'a',
          children: [TestNode(name: 'a', log: log)],
        ),
        RouteNode(
          name: 'b',
          children: [TestNode(name: 'b', log: log)],
        ),
      ],
    ).mount();

    router.go('b', transition: TestTransition(chrome: chrome));
    scene.update(0.5);
    scene.render(canvas);
    expect(log.renders, ['a', 'b', 'chrome']);
  });

  test('the chrome leaves the tree with the swap', () {
    final router = Router<String>();
    final log = TestLog();
    final chrome = TestNode(name: 'chrome', log: log);

    final host = RouterNode(
      router: router,
      children: [
        RouteNode(name: 'a'),
        RouteNode(name: 'b'),
      ],
    );

    final scene = host.mount();
    router.go('b', transition: TestTransition(chrome: chrome));
    scene.update(1);
    expect(router.isTransitioning, isFalse);

    scene.render(canvas);
    expect(log.renders, isEmpty);

    scene.update(0);
    expect(host.children, isNot(contains(chrome)));
  });

  test('a covered route paints without ticking', () {
    final router = Router<String>();
    final a = TestNode(name: 'a');
    final b = TestNode(name: 'b');

    final scene = RouterNode(
      router: router,
      children: [
        RouteNode(name: 'a', children: [a]),
        RouteNode(name: 'b', children: [b]),
      ],
    ).mount();

    router.push('b', transition: TestTransition());
    scene.update(0.5);
    scene.render(canvas);
    expect(a.updates, 0);
    expect(a.renders, 1);
    expect(b.updates, 1);
    expect(b.renders, 1);
  });

  test('a push poses only the incoming side', () {
    final router = Router<String>();
    final ra = RouteNode(name: 'a');
    final rb = RouteNode(name: 'b');
    final scene = RouterNode(router: router, children: [ra, rb]).mount();
    scene.resize(100, 100);

    router.push('b', transition: SlideTransition());
    scene.update(0.5);

    expect(rb.position.y, 50);
    expect(ra.position.y, 0);
    expect(ra.opacity, 1);
  });

  test('stack order is paint order', () {
    final router = Router<String>();
    final log = TestLog();

    final scene = RouterNode(
      router: router,
      children: [
        RouteNode(
          name: 'a',
          children: [TestNode(name: 'a', log: log)],
        ),
        RouteNode(
          name: 'b',
          children: [TestNode(name: 'b', log: log)],
        ),
        RouteNode(
          name: 'c',
          children: [TestNode(name: 'c', log: log)],
        ),
      ],
    ).mount();

    router.push('c', transition: TestTransition());
    scene.update(1);
    router.push('b', transition: TestTransition());
    scene.update(1);

    scene.render(canvas);
    expect(log.renders, ['a', 'c', 'b']);
  });

  test('input stops at the top', () {
    final router = Router<String>();
    final tapA = TapInput(shape: .square(100));
    final tapB = TapInput(shape: .square(100));

    final host = RouterNode(
      router: router,
      children: [
        RouteNode(name: 'a', children: [tapA]),
        RouteNode(name: 'b', children: [tapB]),
      ],
    );

    final scene = host.mount();
    router.push('b', transition: TestTransition());
    scene.update(1);

    final hits = host.hitTest(Vector2.all(10)).toList();
    expect(hits, contains(tapB));
    expect(hits, isNot(contains(tapA)));
  });
}
