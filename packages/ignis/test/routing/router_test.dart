import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_backdrop.dart';
import '../support/test_transition.dart';

void main() {
  test('the first route added is the top', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final router = Router<String>()
      ..add(a)
      ..add(b);

    expect(router.top, 'a');
    expect(router.stack, ['a']);
    expect(a.activity, Activity.all);
    expect(b.activity, Activity.none);
  });

  test('a named top wins over registration order', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final router = Router(top: 'b')
      ..add(a)
      ..add(b);

    expect(router.top, 'b');
    expect(a.activity, Activity.none);
    expect(b.activity, Activity.all);
  });

  test('go commits at the call', () {
    final router = Router<String>()
      ..add(RouteNode(name: 'a'))
      ..add(RouteNode(name: 'b'));

    router.go('b', transition: TestTransition());
    expect(router.top, 'b');
    expect(router.isTransitioning, isTrue);
  });

  test('a swap runs both sides live and settles to one', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final router = Router<String>()
      ..add(a)
      ..add(b);

    router.go('b', transition: TestTransition());
    router.process(0.5);
    expect(router.progress, 0.5);
    expect(a.activity, Activity.all, reason: 'the outgoing side is live mid-swap');
    expect(b.activity, Activity.all, reason: 'the incoming side is live mid-swap');

    router.process(0.5);
    expect(router.isTransitioning, isFalse);
    expect(a.activity, Activity.none, reason: 'settling retired the loser');
    expect(b.activity, Activity.all);
  });

  test('a swap poses both sides through its transition', () {
    final transition = TestTransition();
    final router = Router<String>()
      ..add(RouteNode(name: 'a'))
      ..add(RouteNode(name: 'b'));

    router.go('b', transition: transition);
    router.process(0.25);
    router.process(0.25);
    expect(transition.applies, [0, 0.25, 0.5]);
  });

  test('settling returns both sides to rest', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final router = Router<String>()
      ..add(a)
      ..add(b);

    router.go('b', transition: FadeTransition());
    router.process(0.5);
    expect(b.opacity, 0.5);

    router.process(0.5);
    expect(router.isTransitioning, isFalse);
    expect(a.opacity, 1);
    expect(b.opacity, 1);
    expect(a.enabled, isFalse);
  });

  test('going back to the departed route mid-swap reverses to it', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final router = Router<String>()
      ..add(a)
      ..add(b);

    router.go('b', transition: TestTransition());
    router.process(0.3);

    router.go('a');
    expect(router.top, 'a');

    router.process(0.4);
    expect(router.isTransitioning, isFalse);
    expect(a.activity, Activity.all);
    expect(b.activity, Activity.none, reason: 'the abandoned side settled retired');
  });

  test('going to the target mid-swap keeps it running forward', () {
    final router = Router<String>()
      ..add(RouteNode(name: 'a'))
      ..add(RouteNode(name: 'b'));

    router.go('b', transition: TestTransition());
    router.process(0.3);
    router.go('a');
    router.process(0.2);

    router.go('b');
    expect(router.top, 'b');

    router.process(1);
    expect(router.isTransitioning, isFalse);
    expect(router.top, 'b');
  });

  test('going to a third route completes the running swap first', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final c = RouteNode(name: 'c');
    final router = Router<String>()
      ..add(a)
      ..add(b)
      ..add(c);

    router.go('b', transition: TestTransition());
    router.process(0.3);

    router.go('c', transition: TestTransition());
    expect(router.top, 'c');
    expect(router.isTransitioning, isTrue);

    router.process(1);
    expect(router.isTransitioning, isFalse);
    expect(a.activity, Activity.none);
    expect(b.activity, Activity.none);
    expect(c.activity, Activity.all);
  });

  test('going to the top is a no-op', () {
    final router = Router<String>()
      ..add(RouteNode(name: 'a'))
      ..add(RouteNode(name: 'b'));

    router.go('a');
    expect(router.isTransitioning, isFalse);
  });

  test('a swap layers the outgoing side beneath the incoming one, and the chrome above', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final chrome = Node(enabled: false);
    final router = Router<String>()
      ..add(a)
      ..add(b);

    router.go('b', transition: TestTransition(chrome: chrome));
    expect(a.priority, -1);
    expect(b.priority, 0);
    expect(chrome.priority, 2);
    expect(chrome.enabled, isTrue);
  });

  test('a navigation announces its start and its settle', () {
    final transition = TestTransition(chrome: Node());
    final starts = <Transition>[];
    final settles = <Transition>[];
    final router = Router<String>()
      ..add(RouteNode(name: 'a'))
      ..add(RouteNode(name: 'b'));

    router.onStart((transition) {
      starts.add(transition);
    });

    router.onSettle((transition) {
      settles.add(transition);
    });

    router.go('b', transition: transition);
    expect(starts, [transition]);
    expect(settles, isEmpty);

    router.process(1);
    expect(settles, [transition]);
    expect(transition.chrome!.enabled, isFalse);
  });

  test('a route added late takes no part', () {
    final c = RouteNode(name: 'c');
    final router = Router<String>()
      ..add(RouteNode(name: 'a'))
      ..add(RouteNode(name: 'b'));

    router.add(c);
    expect(c.activity, Activity.none);

    router.go('c');
    router.process(0);
    expect(c.activity, Activity.all);
  });

  test('an unknown name trips the assert', () {
    final router = Router<String>()..add(RouteNode(name: 'a'));

    expect(() => router.go('nope'), throwsA(isA<AssertionError>()));
  });

  test('duplicate names trip the assert', () {
    final router = Router<String>()..add(RouteNode(name: 'a'));

    expect(() => router.add(RouteNode(name: 'a')), throwsA(isA<AssertionError>()));
  });

  test('a removed route cannot be named', () {
    final b = RouteNode(name: 'b');
    final router = Router<String>()
      ..add(RouteNode(name: 'a'))
      ..add(b);

    router.remove(b);
    expect(() => router.go('b'), throwsA(isA<AssertionError>()));
  });

  test('removing a side settles the navigation', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final router = Router<String>()
      ..add(a)
      ..add(b);

    router.go('b', transition: TestTransition());
    router.process(0.3);

    router.remove(b);
    expect(router.isTransitioning, isFalse);
    expect(a.activity, Activity.all);
  });

  test('a push lays a route over the top and freezes the covered one', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final router = Router<String>()
      ..add(a)
      ..add(b);

    router.push('b', transition: TestTransition());
    expect(router.top, 'b');
    expect(router.stack, ['a', 'b']);
    expect(a.activity, Activity.render, reason: 'paints through the transition');
    expect(b.activity, Activity.all);

    router.process(1);
    expect(router.isTransitioning, isFalse);
    expect(a.activity, Activity.render);
    expect(b.activity, Activity.all);
  });

  test('a live backdrop keeps its activity under a push', () {
    final a = RouteNode(name: 'a');
    final router = Router<String>()
      ..add(a)
      ..add(RouteNode(name: 'b'));

    router.push('b', transition: TestTransition(), backdrop: .live());
    router.process(1);

    expect(a.activity, Activity.update | Activity.render);
    expect(a.activity.inputs, isFalse);
  });

  test('a hidden backdrop paints through the transition, then not at all', () {
    final a = RouteNode(name: 'a');
    final router = Router<String>()
      ..add(a)
      ..add(RouteNode(name: 'b'));

    router.push('b', transition: TestTransition(), backdrop: .hidden());
    router.process(0.5);
    expect(a.activity, Activity.render);

    router.process(0.5);
    expect(a.activity, Activity.none);
  });

  test('a pop reverses the push and wakes the route beneath', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final router = Router<String>()
      ..add(a)
      ..add(b);

    router.push('b', transition: TestTransition());
    router.process(1);

    router.pop();
    expect(router.top, 'a');
    expect(router.stack, ['a']);
    expect(router.isTransitioning, isTrue);

    router.process(1);
    expect(router.isTransitioning, isFalse);
    expect(b.activity, Activity.none);
    expect(a.activity, Activity.all);
  });

  test('a pop mid-push reverses in place', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final router = Router<String>()
      ..add(a)
      ..add(b);

    router.push('b', transition: TestTransition());
    router.process(0.3);
    router.pop();
    expect(router.top, 'a');

    router.process(0.3);
    expect(router.isTransitioning, isFalse);
    expect(b.activity, Activity.none);
    expect(a.activity, Activity.all);
  });

  test('go collapses the stack', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final c = RouteNode(name: 'c');
    final router = Router<String>()
      ..add(a)
      ..add(b)
      ..add(c);

    router.push('b', transition: TestTransition());
    router.process(1);

    router.go('c', transition: TestTransition());
    expect(router.stack, ['c']);

    router.process(1);
    expect(a.activity, Activity.none);
    expect(b.activity, Activity.none);
    expect(c.activity, Activity.all);
  });

  test('stack order is priority order', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final c = RouteNode(name: 'c');
    final router = Router<String>()
      ..add(a)
      ..add(b)
      ..add(c);

    router.push('c', transition: TestTransition());
    router.process(1);
    router.push('b', transition: TestTransition());
    router.process(1);

    expect(a.priority, 0);
    expect(c.priority, 1);
    expect(b.priority, 2);
  });

  test('push of a stacked route trips the assert', () {
    final router = Router<String>()..add(RouteNode(name: 'a'));

    expect(() => router.push('a'), throwsA(isA<AssertionError>()));
  });

  test('pop of a stack of one throws', () {
    final router = Router<String>()..add(RouteNode(name: 'a'));

    expect(() => router.pop(), throwsStateError);
  });

  test('a push completes with what its pop carries', () async {
    final router = Router<String>()
      ..add(RouteNode(name: 'a'))
      ..add(RouteNode(name: 'b'));

    final result = router.push<int>('b');
    router.pop(3);
    expect(await result, 3);
  });

  test('a bare pop completes its push with null', () async {
    final router = Router<String>()
      ..add(RouteNode(name: 'a'))
      ..add(RouteNode(name: 'b'));

    final result = router.push<int>('b');
    router.pop();
    expect(await result, isNull);
  });

  test('go completes every push it drops with null', () async {
    final router = Router<String>()
      ..add(RouteNode(name: 'a'))
      ..add(RouteNode(name: 'b'))
      ..add(RouteNode(name: 'c'))
      ..add(RouteNode(name: 'd'));

    final b = router.push<int>('b');
    router.process(1);
    final c = router.push<int>('c');
    router.process(1);

    router.go('d');
    expect(await b, isNull);
    expect(await c, isNull);
  });

  test('a mistyped result throws at the pop', () {
    final router = Router<String>()
      ..add(RouteNode(name: 'a'))
      ..add(RouteNode(name: 'b'));

    router.push<int>('b');
    expect(() => router.pop('three'), throwsA(isA<TypeError>()));
  });

  test('a push poses its backdrop, and a pop plays it back', () {
    final backdrop = TestBackdrop();
    final router = Router<String>()
      ..add(RouteNode(name: 'a'))
      ..add(RouteNode(name: 'b'));

    router.push('b', transition: TestTransition(), backdrop: backdrop);
    router.process(0.5);
    expect(backdrop.applies, [0, 0.5]);

    router.process(0.5);
    router.pop();
    router.process(0.5);
    expect(backdrop.applies, [0, 0.5, 1, 0.5]);
  });

  test('settling returns the covered route to rest', () {
    final a = RouteNode(name: 'a');
    final router = Router<String>()
      ..add(a)
      ..add(RouteNode(name: 'b'));

    router.push('b', transition: TestTransition(), backdrop: TestBackdrop());
    router.process(0.5);
    expect(a.opacity, 0.5);

    router.process(0.5);
    expect(router.isTransitioning, isFalse);
    expect(a.opacity, 1);
  });

  test('a backdrop may tick while the push runs and freeze at settle', () {
    final a = RouteNode(name: 'a');
    final router = Router<String>()
      ..add(a)
      ..add(RouteNode(name: 'b'));

    router.push(
      'b',
      transition: TestTransition(),
      backdrop: TestBackdrop(running: Activity.update | Activity.render),
    );

    expect(a.activity, Activity.update | Activity.render);
    router.process(1);
    expect(a.activity, Activity.render);
  });

  test('a covered route rests in the backdrop of the push above it', () {
    final a = RouteNode(name: 'a');
    final b = RouteNode(name: 'b');
    final router = Router<String>()
      ..add(a)
      ..add(b)
      ..add(RouteNode(name: 'c'));

    router.push('b', backdrop: .hidden());
    router.process(0);
    router.push('c');
    router.process(0);

    expect(a.activity, Activity.none);
    expect(b.activity, Activity.render);
  });
}
