import 'package:flutter/animation.dart' show Curves;
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_transition.dart';

void main() {
  test('reveals `to` at exactly `swapAt`', () {
    final to = SpatialNode();
    final transition = TestTransition(to, null, swapAt: 0.5);
    final scene = Node(children: [to, transition]).mount();

    var swaps = 0;
    transition.onSwap(() => swaps += 1);

    scene.update(0.25);
    expect(to.enabled, isFalse);
    expect(transition.isSwapped, isFalse);

    scene.update(0.25);
    expect(to.enabled, isTrue);
    expect(transition.isSwapped, isTrue);
    expect(swaps, 1);

    scene.update(0.25);
    expect(swaps, 1);
  });

  test('a `swapAt` of 0 swaps on the first tick', () {
    final to = SpatialNode();
    final transition = TestTransition(to, null, swapAt: 0);
    final scene = Node(children: [to, transition]).mount();

    scene.update(0);
    expect(to.enabled, isTrue);
    expect(transition.isSwapped, isTrue);
    expect(transition.isFinished, isFalse);
  });

  test('a cut swaps and finishes in one tick', () {
    final to = SpatialNode();
    final transition = CutTransitionEffect(to, null);
    final scene = Node(children: [to, transition]).mount();

    scene.update(0);
    expect(to.enabled, isTrue);
    expect(transition.isFinished, isTrue);
  });

  test('adopts a parentless `to` and disables it until the swap', () {
    final to = SpatialNode();
    final transition = TestTransition(to, null, swapAt: 0.5);
    final scene = Node(children: [transition]).mount();

    scene.update(0.25);
    expect(to.isMounted, isTrue);
    expect(to.enabled, isFalse);

    scene.update(0.25);
    expect(to.enabled, isTrue);
  });

  test('`to` and `from` must be different nodes', () {
    final node = SpatialNode();

    expect(() => CutTransitionEffect(node, node), throwsA(isA<AssertionError>()));
  });

  test('a transition with no `from` swaps and finishes cleanly', () {
    final to = SpatialNode();
    final transition = TestTransition(to, null, swapAt: 0.5);
    final scene = Node(children: [to, transition]).mount();

    scene.update(1);
    expect(to.enabled, isTrue);
    expect(transition.isSwapped, isTrue);
    expect(transition.isFinished, isTrue);
  });

  test('finishing resets the positions the transition drove', () {
    final from = SpatialNode();
    final to = SpatialNode();
    final transition = SlideTransitionEffect(to, from);
    final scene = Node(children: [from, to, transition]).mount();
    scene.resize(100, 100);

    scene.update(0.5);
    expect(to.position.y, 50);
    expect(from.position.y, -50);

    scene.update(0.5);
    expect(to.position.y, 0);
    expect(from.position.y, 0);
  });

  test('finishing resets the opacities the transition drove', () {
    final from = SpatialNode();
    final to = SpatialNode();
    final transition = FadeTransitionEffect(to, from, crossFade: true);
    final scene = Node(children: [from, to, transition]).mount();

    scene.update(0.5);
    expect(to.opacity, 0.5);
    expect(from.opacity, 0.5);

    scene.update(0.5);
    expect(to.opacity, 1);
    expect(from.opacity, 1);
  });

  test('outcomes compose through onFinish, like detaching from', () {
    final from = SpatialNode();
    final to = SpatialNode();
    final transition = TestTransition(to, from);
    final scene = Node(children: [from, to, transition]).mount();
    transition.onFinish(() => from.detach());

    scene.update(1);
    scene.update(0);
    expect(from.isMounted, isFalse);
  });

  test('cleanup detaches the transition once finished', () {
    final to = SpatialNode();
    final transition = TestTransition(to, null, cleanup: true);
    final scene = Node(children: [to, transition]).mount();

    scene.update(1);
    expect(transition.isMounted, isTrue);

    scene.update(0);
    expect(transition.isMounted, isFalse);
  });

  test('apply is driven by its curve', () {
    final to = SpatialNode();
    final transition = TestTransition(to, null, controller: .duration(1, Curves.easeIn));
    final scene = Node(children: [to, transition]).mount();

    scene.update(0.123);
    expect(transition.applies.single, Curves.easeIn.transform(0.123));
  });

  test('force-finishing after the swap completes the transition', () {
    final from = SpatialNode();
    final to = SpatialNode();
    final transition = SlideTransitionEffect(to, from);
    final scene = Node(children: [from, to, transition]).mount();
    scene.resize(100, 100);

    var finishes = 0;
    transition.onFinish(() => finishes += 1);

    scene.update(0.3);
    expect(transition.isSwapped, isTrue);
    expect(to.position.y, 70);

    transition.controller.setToEnd();
    transition.update(0);

    expect(finishes, 1);
    expect(transition.isFinished, isTrue);
    expect(to.position.y, 0);
    expect(from.position.y, 0);

    scene.update(0.1);
    expect(finishes, 1);
  });

  test('force-finishing before the swap completes the transition', () {
    final to = SpatialNode();
    final transition = TestTransition(to, null, swapAt: 0.9);
    final scene = Node(children: [to, transition]).mount();

    var swaps = 0;
    transition.onSwap(() => swaps += 1);

    scene.update(0.3);
    expect(transition.isSwapped, isFalse);

    transition.controller.setToEnd();
    transition.update(0);

    expect(swaps, 1);
    expect(to.enabled, isTrue);
  });
}
