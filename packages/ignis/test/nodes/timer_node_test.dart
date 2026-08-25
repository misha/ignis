import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('defaults to firing once, with count defaulting to 1, without detaching', () {
    final node = TimerNode(interval: 1);

    expect(node.repeat, isFalse);
    expect(node.count, 1);
    expect(node.cleanup, isFalse);
  });

  test('passing null for repeat, count, or cleanup falls back to their defaults', () {
    final node = TimerNode(interval: 1, repeat: null, count: null, cleanup: null);

    expect(node.repeat, isFalse);
    expect(node.count, 1);
    expect(node.cleanup, isFalse);
  });

  test('emits onTrigger once interval seconds elapse', () {
    final node = TimerNode(interval: 1);
    node.mount();
    var triggers = 0;
    node.onTrigger(() => triggers += 1);

    node.update(0.5);
    expect(triggers, 0);

    node.update(0.5);
    expect(triggers, 1);
  });

  test('detaches itself once it triggers, when cleanup is true', () {
    final a = Node();
    final timer = TimerNode(interval: 1, cleanup: true);
    a.add(timer);
    final scene = a.mount();
    var triggers = 0;
    timer.onTrigger(() => triggers += 1);

    scene.update(0.5);
    expect(triggers, 0);
    expect(timer.isFinished, isFalse);
    expect(a.children, [timer]);

    scene.update(0.5);
    expect(triggers, 1);
    expect(timer.isFinished, isTrue);
    expect(a.children, [timer]); // Still pending.

    scene.update(0);
    expect(a.children, isEmpty);
  });

  test('triggers count times before finishing, then detaches', () {
    final a = Node();
    final timer = TimerNode(interval: 1, count: 2, cleanup: true);
    a.add(timer);
    final scene = a.mount();
    var triggers = 0;
    timer.onTrigger(() => triggers += 1);

    scene.update(3);
    expect(triggers, 2);

    scene.update(0);
    expect(a.children, isEmpty);
  });

  test('repeat overrides count, triggering indefinitely', () {
    final a = Node();
    final timer = TimerNode(interval: 1, repeat: true, count: 1);
    a.add(timer);
    final scene = a.mount();
    var triggers = 0;
    timer.onTrigger(() => triggers += 1);

    scene.update(5.5);
    expect(triggers, 5);
    expect(timer.isFinished, isFalse); // Never finishes, so it never detaches.
    expect(a.children, [timer]);
  });

  test('does not detach when finished if cleanup is false', () {
    final a = Node();
    final timer = TimerNode(interval: 1, cleanup: false);
    a.add(timer);
    final scene = a.mount();
    var triggers = 0;
    timer.onTrigger(() => triggers += 1);

    scene.update(1);
    expect(triggers, 1);
    expect(timer.isFinished, isTrue);

    scene.update(5);
    expect(triggers, 1); // Finished, so further ticks are no-ops.
    expect(a.children, [timer]);
  });

  test('reset restarts a finished timer that was not cleaned up', () {
    final timer = TimerNode(interval: 1, cleanup: false);
    timer.mount();
    var triggers = 0;
    timer.onTrigger(() => triggers += 1);

    timer.update(1);
    expect(triggers, 1);

    timer.update(1);
    expect(triggers, 1); // Finished, so this tick is a no-op.

    timer.reset();
    expect(timer.isFinished, isFalse);

    timer.update(1);
    expect(triggers, 2);
  });

  test('reset lets a count-limited timer trigger count more times', () {
    final timer = TimerNode(interval: 1, count: 2, cleanup: false);
    timer.mount();
    var triggers = 0;
    timer.onTrigger(() => triggers += 1);

    timer.update(3);
    expect(triggers, 2);

    timer.reset();
    timer.update(3);
    expect(triggers, 4);
  });
}
