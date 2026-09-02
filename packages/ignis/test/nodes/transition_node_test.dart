import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/canvas.dart';
import '../support/test_node.dart';
import '../support/test_transition.dart';

void main() {
  final canvas = RecordingCanvas();

  test('the first registered group shows, the rest are disabled', () {
    final a = TestNode(name: 'a');
    final b = TestNode(name: 'b');

    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(name: 'a', children: [a]),
        TransitionGroupNode(name: 'b', children: [b]),
      ],
    );

    final scene = Node(children: [host]).mount();
    expect(host.shown, 'a');

    scene.render(canvas);
    expect(a.renders, 1);
    expect(b.renders, 0);
  });

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

    final scene = Node(children: [host]).mount();
    expect(host.shown, 'b');

    scene.render(canvas);
    expect(a.renders, 0);
    expect(b.renders, 1);
  });

  test('a show before mounting begins once its groups register', () {
    final a = TestNode(name: 'a');
    final b = TestNode(name: 'b');
    final host = _stage(a: a, b: b);

    host.show('b', transition: TestTransition.new);
    expect(host.shown, 'b');

    final scene = Node(children: [host]).mount();
    expect(host.isTransitioning, isTrue);

    scene.update(1);
    expect(host.isTransitioning, isFalse);

    scene.render(canvas);
    expect(a.renders, 0);
    expect(b.renders, 1);
  });

  test('shown commits at the show call', () {
    final host = _stage();
    Node(children: [host]).mount();

    host.show('b', transition: TestTransition.new);
    expect(host.shown, 'b');
    expect(host.isTransitioning, isTrue);
  });

  test('a swap runs both sides live and settles to one', () {
    final a = TestNode(name: 'a');
    final b = TestNode(name: 'b');
    final host = _stage(a: a, b: b);
    final scene = Node(children: [host]).mount();
    scene.update(1);
    final aTicked = a.updates;

    host.show('b', transition: TestTransition.new);
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
    final a = TransitionGroupNode(
      name: 'a',
      children: [TestNode(name: 'a')],
    );

    final b = TransitionGroupNode(
      name: 'b',
      children: [TestNode(name: 'b')],
    );

    final host = TransitionNode<String>(children: [a, b]);
    final scene = Node(children: [host]).mount();

    host.show('b', transition: FadeTransition.new);
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
    final host = _stage(a: a, b: b);
    final scene = Node(children: [host]).mount();

    host.show('b', transition: TestTransition.new);
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
    final host = _stage();
    final scene = Node(children: [host]).mount();

    host.show('b', transition: TestTransition.new);
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
    final host = _stage(a: a, b: b, c: c);
    final scene = Node(children: [host]).mount();

    host.show('b', transition: TestTransition.new);
    scene.update(0.3);

    host.show('c', transition: TestTransition.new);
    expect(host.shown, 'c');
    expect(host.isTransitioning, isTrue);

    scene.update(1);
    expect(host.isTransitioning, isFalse);

    scene.render(canvas);
    expect(a.renders, 0);
    expect(b.renders, 0);
    expect(c.renders, 1);
  });

  test('nothing outside a group is touched by a swap', () {
    final outsider = TestNode(name: 'outsider');
    final host = _stage(outsider: outsider);
    final scene = Node(children: [host]).mount();

    host.show('b', transition: TestTransition.new);
    scene.update(0.5);

    scene.render(canvas);
    expect(outsider.updates, greaterThan(0));
    expect(outsider.renders, 1);
  });

  test('a group registers from depth', () {
    final deep = TestNode(name: 'deep');

    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(
          name: 'a',
          children: [TestNode(name: 'a')],
        ),
        Node(
          children: [
            TransitionGroupNode(
              name: 'b',
              children: [deep],
            ),
          ],
        ),
      ],
    );

    final scene = Node(children: [host]).mount();
    host.show('b');
    scene.update(0);

    scene.render(canvas);
    expect(deep.renders, 1);
  });

  test('a group that mounts late registers disabled', () {
    final joined = TestNode(name: 'late');
    final host = _stage();
    final scene = Node(children: [host]).mount();

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
    final host = _stage();
    Node(children: [host]).mount();

    expect(() => host.show('nope'), throwsA(isA<AssertionError>()));
  });

  test('showing the shown name is a no-op', () {
    final host = _stage();
    Node(children: [host]).mount();

    host.show('a');
    expect(host.isTransitioning, isFalse);
  });

  test('a detached group unregisters', () {
    final b = TransitionGroupNode<String>(
      name: 'b',
      children: [TestNode(name: 'b')],
    );

    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(
          name: 'a',
          children: [TestNode(name: 'a')],
        ),
        b,
      ],
    );

    final scene = Node(children: [host]).mount();
    host.remove(b);
    scene.update(0);

    expect(() => host.show('b'), throwsA(isA<AssertionError>()));
  });

  test('duplicate names trip the assert', () {
    final host = TransitionNode<String>(
      children: [
        TransitionGroupNode(name: 'a', children: [TestNode()]),
        TransitionGroupNode(name: 'a', children: [TestNode()]),
      ],
    );

    expect(() => Node(children: [host]).mount(), throwsA(isA<AssertionError>()));
  });

  test('a group without a host throws', () {
    expect(
      () => Node(children: [TransitionGroupNode(name: 'a')]).mount(),
      throwsA(isA<StateError>()),
    );
  });
}

TransitionNode<String> _stage({TestNode? a, TestNode? b, TestNode? c, TestNode? outsider}) {
  return TransitionNode(
    children: [
      TransitionGroupNode(
        name: 'a',
        children: [a ?? TestNode(name: 'a')],
      ),
      TransitionGroupNode(
        name: 'b',
        children: [b ?? TestNode(name: 'b')],
      ),
      if (c != null) TransitionGroupNode(name: 'c', children: [c]),
      ?outsider,
    ],
  );
}
