import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

class _MutableDistanceEffect extends ControlledEffect implements MeasurableEffect {
  double distance;

  _MutableDistanceEffect(
    this.distance, {
    required super.controller,
  });

  @override
  double measure() => distance;
}

void main() {
  test('asserts speed is positive', () {
    expect(() => SpeedEffectController(0), throwsAssertionError);
    expect(() => SpeedEffectController(-1), throwsAssertionError);
  });

  test('asserts its attached effect is a MeasurableEffect', () {
    expect(
      () => ControlledEffect(controller: .speed(10)),
      throwsAssertionError,
    );
  });

  test('throws if advance()/recede() force a resolution before it is attached', () {
    expect(() => SpeedEffectController(10).advance(1), throwsStateError);
    expect(() => SpeedEffectController(10).recede(1), throwsStateError);
  });

  test('hasStarted/isFinished/progress are safe defaults before anything else happens', () {
    final controller = SpeedEffectController(10);

    expect(controller.hasStarted, isFalse);
    expect(controller.isFinished, isFalse);
    expect(controller.progress, 0);
    expect(controller.duration, isNull);
  });

  test('duration is unknown even once attached, until it is safe to resolve', () {
    final effect = MoveEffect.by(
      offset: .new(30, 40),
      controller: .speed(10),
    );

    expect(effect.controller.duration, isNull); // Attached, but not yet resolved.

    effect.controller.advance(0); // Forces resolution without progressing.
    expect(effect.controller.duration, 5);
  });

  test('measures lazily, after mount-time state the effect computes', () {
    final node = TransformNode(position: .zero());
    final scene = node.mount();
    final effect = MoveEffect.to(
      destination: .new(30, 40),
      controller: .speed(10),
    ); // Distance 50.

    node.add(effect);
    expect(effect.controller.duration, isNull); // Not yet mounted, so not yet resolved.

    scene.update(0); // Flushes the mount, snapshotting the offset, then ticks once.
    expect(effect.controller.duration, 5);
    expect(effect.controller.progress, 0);
  });

  test('finishes instantly when the measured distance is 0', () {
    final controller = SpeedEffectController(10);
    MoveEffect.by(offset: .zero(), controller: controller);

    expect(controller.duration, isNull); // Not yet resolved.
    expect(controller.advance(1), 1);
    expect(controller.duration, 0);
    expect(controller.isFinished, isTrue);
    expect(controller.progress, 1);
  });

  test('caches its measured distance permanently; setToStart() does not re-measure', () {
    final effect = _MutableDistanceEffect(10, controller: .speed(10));
    final controller = effect.controller;

    controller.advance(0.5);
    expect(controller.progress, 0.5);

    controller.setToStart();
    expect(controller.progress, 0);

    effect.distance = 20; // Ignored: measure() is never called again.
    controller.advance(1);
    expect(controller.progress, 1); // Finished after 1s, not halfway through 20/10 = 2s.
  });

  test('caches its measured distance permanently; receding past the start does not re-measure', () {
    final effect = _MutableDistanceEffect(10, controller: .speed(10));
    final controller = effect.controller;

    controller.advance(1);
    expect(controller.recede(1.5), 0.5); // Only 1s of progress to give back.

    effect.distance = 20; // Ignored: measure() is never called again.
    controller.advance(1);
    expect(controller.progress, 1); // Finished after 1s, not halfway through 20/10 = 2s.
  });

  test('nests inside repeat, sequence, and infinite controllers', () {
    final repeat = MoveEffect.by(
      offset: .new(6, 8),
      controller: .repeat(.speed(10), 2),
    );

    expect(repeat.controller.advance(1.5), 0);
    expect(repeat.controller.progress, 0.5);

    final sequence = MoveEffect.by(
      offset: .new(6, 8),
      controller: .sequence([.speed(10), .duration(1)]),
    );

    expect(sequence.controller.advance(1.5), 0);
    expect(sequence.controller.progress, 0.5);

    final infinite = MoveEffect.by(
      offset: .new(6, 8),
      controller: .infinite(.speed(10)),
    );

    expect(infinite.controller.advance(1.5), 0);
    expect(infinite.controller.progress, 0.5);
  });

  test('cannot be nested inside roundtrip: its duration is unknown at construction', () {
    expect(
      () => RoundtripEffectController(SpeedEffectController(10)),
      throwsAssertionError,
    );
  });
}
