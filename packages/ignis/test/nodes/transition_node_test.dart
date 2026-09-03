import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/canvas.dart';
import '../support/test_node.dart';
import '../support/test_transition.dart';

void main() {
  final canvas = RecordingCanvas();

  test('a shown name picks the showing group over registration order', () {
    final a = TestNode(name: 'a');
    final b = TestNode(name: 'b');

    final host = TransitionNode<String>(
      shown: 'b',
      children: [
        TransitionGroupNode(name: 'a', children: [a]),
        TransitionGroupNode(name: 'b', children: [b]),
      ],
    );

    final scene = host.mount();
    expect(host.shown, 'b');

    scene.render(canvas);
    expect(a.renders, 0);
    expect(b.renders, 1);
  });

  test('shown commits at the show call', () {
    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(name: 'a'),
        TransitionGroupNode(name: 'b'),
      ],
    );

    host.mount();
    host.show('b', transition: TestTransition());
    expect(host.shown, 'b');
    expect(host.isTransitioning, isTrue);
  });

  test('a swap runs both sides live and settles to one', () {
    final a = TestNode(name: 'a');
    final b = TestNode(name: 'b');

    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(name: 'a', children: [a]),
        TransitionGroupNode(name: 'b', children: [b]),
      ],
    );

    final scene = host.mount();
    scene.update(1);
    final aTicked = a.updates;

    host.show('b', transition: TestTransition());
    scene.update(0.5);
    scene.render(canvas);
    expect(a.renders, 1, reason: 'the outgoing side paints mid-swap');
    expect(b.renders, 1, reason: 'the incoming side paints mid-swap');
    expect(a.updates, greaterThan(aTicked), reason: 'the outgoing side ticks mid-swap');
    expect(b.updates, greaterThan(0), reason: 'the incoming side ticks mid-swap');

    scene.update(0.5);
    expect(host.isTransitioning, isFalse);

    scene.render(canvas);
    expect(a.renders, 1, reason: 'settling disabled the loser');
    expect(b.renders, 2);
  });

  test('settling returns both sides to rest', () {
    final a = TransitionGroupNode(name: 'a');
    final b = TransitionGroupNode(name: 'b');
    final host = TransitionNode<String>(children: [a, b]);
    final scene = host.mount();

    host.show('b', transition: FadeTransition());
    scene.update(0.5);
    expect(b.opacity, 0.5);

    scene.update(0.5);
    expect(host.isTransitioning, isFalse);
    expect(a.opacity, 1);
    expect(b.opacity, 1);
    expect(a.enabled, isFalse);
  });

  test('showing the departed name mid-swap reverses to it', () {
    final a = TestNode(name: 'a');
    final b = TestNode(name: 'b');

    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(name: 'a', children: [a]),
        TransitionGroupNode(name: 'b', children: [b]),
      ],
    );

    final scene = host.mount();
    host.show('b', transition: TestTransition());
    scene.update(0.3);

    host.show('a');
    expect(host.shown, 'a');

    scene.update(0.4);
    expect(host.isTransitioning, isFalse);

    scene.render(canvas);
    expect(a.renders, 1);
    expect(b.renders, 0, reason: 'the abandoned side settled disabled');
  });

  test('showing the target mid-swap keeps it running forward', () {
    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(name: 'a'),
        TransitionGroupNode(name: 'b'),
      ],
    );

    final scene = host.mount();
    host.show('b', transition: TestTransition());
    scene.update(0.3);
    host.show('a');
    scene.update(0.2);

    host.show('b');
    expect(host.shown, 'b');

    scene.update(1);
    expect(host.isTransitioning, isFalse);
    expect(host.shown, 'b');
  });

  test('showing a third name completes the running swap first', () {
    final a = TestNode(name: 'a');
    final b = TestNode(name: 'b');
    final c = TestNode(name: 'c');

    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(name: 'a', children: [a]),
        TransitionGroupNode(name: 'b', children: [b]),
        TransitionGroupNode(name: 'c', children: [c]),
      ],
    );

    final scene = host.mount();
    host.show('b', transition: TestTransition());
    scene.update(0.3);

    host.show('c', transition: TestTransition());
    expect(host.shown, 'c');
    expect(host.isTransitioning, isTrue);

    scene.update(1);
    expect(host.isTransitioning, isFalse);

    scene.render(canvas);
    expect(a.renders, 0);
    expect(b.renders, 0);
    expect(c.renders, 1);
  });

  test('a swap layers the outgoing side, the incoming side, then the chrome', () {
    final log = TestLog();
    final chrome = TestNode(name: 'chrome', log: log);

    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(
          name: 'a',
          children: [TestNode(name: 'a', log: log)],
        ),
        TransitionGroupNode(
          name: 'b',
          children: [TestNode(name: 'b', log: log)],
        ),
      ],
    );

    final scene = host.mount();

    host.show(
      'b',
      transition: TestTransition(chrome: chrome),
    );

    scene.update(0.5);
    scene.render(canvas);
    expect(log.renders, ['a', 'b', 'chrome']);
  });

  test('the chrome leaves with the swap', () {
    final log = TestLog();
    final chrome = TestNode(name: 'chrome', log: log);

    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(name: 'a'),
        TransitionGroupNode(name: 'b'),
      ],
    );

    final scene = host.mount();

    host.show(
      'b',
      transition: TestTransition(chrome: chrome),
    );

    scene.update(1);
    expect(host.isTransitioning, isFalse);

    scene.render(canvas);
    expect(log.renders, isEmpty);

    scene.update(0);
    expect(host.children, isNot(contains(chrome)));
  });

  test('a group that mounts late registers disabled', () {
    final joined = TestNode(name: 'late');

    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(name: 'a'),
        TransitionGroupNode(name: 'b'),
      ],
    );

    final scene = host.mount();
    host.add(TransitionGroupNode(name: 'c', children: [joined]));
    scene.update(0);

    scene.render(canvas);
    expect(joined.renders, 0);

    host.show('c');
    scene.update(0);

    scene.render(canvas);
    expect(joined.renders, 1);
  });

  test('an unknown name trips the assert', () {
    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(name: 'a'),
        TransitionGroupNode(name: 'b'),
      ],
    );

    host.mount();
    expect(() => host.show('nope'), throwsA(isA<AssertionError>()));
  });

  test('showing the shown name is a no-op', () {
    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(name: 'a'),
        TransitionGroupNode(name: 'b'),
      ],
    );

    host.mount();
    host.show('a');
    expect(host.isTransitioning, isFalse);
  });

  test('a detached group unregisters', () {
    final b = TransitionGroupNode(name: 'b');
    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(name: 'a'),
        b,
      ],
    );
    final scene = host.mount();

    host.remove(b);
    scene.update(0);
    expect(() => host.show('b'), throwsA(isA<AssertionError>()));
  });

  test('duplicate names trip the assert', () {
    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(name: 'a'),
        TransitionGroupNode(name: 'a'),
      ],
    );

    expect(() => host.mount(), throwsA(isA<AssertionError>()));
  });

  test('a group not directly under a host throws', () {
    expect(
      () => TransitionGroupNode(name: 'a').mount(),
      throwsA(isA<StateError>()),
    );

    final host = TransitionNode<String>(
      children: [
        Node(children: [TransitionGroupNode(name: 'a')]),
      ],
    );

    expect(() => host.mount(), throwsA(isA<StateError>()));
  });

  test('a group takes the scene as its region with nothing above', () {
    final group = TransitionGroupNode(name: 'a');
    final scene = TransitionNode<String>(children: [group]).mount();
    scene.resize(100, 100);

    expect(group.size, Vector2.all(100));
  });

  test('a group takes the shape in effect above its host', () {
    final group = TransitionGroupNode(name: 'a');

    ClipNode(
      shape: .rectangle(.new(60, 40)),
      children: [
        TransitionNode<String>(children: [group]),
      ],
    ).mount();

    expect(group.size, Vector2(60, 40));
  });
}
