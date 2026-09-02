import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

class _MutableDistanceEffect extends TimelineEffect implements MeasurableEffect {
  double distance;

  _MutableDistanceEffect(
    this.distance, {
    required super.timeline,
  });

  @override
  double measure() => distance;
}

void main() {
  test('asserts speed is positive', () {
    expect(() => SpeedTimeline(0), throwsAssertionError);
    expect(() => SpeedTimeline(-1), throwsAssertionError);
  });

  test('throws on advance, recede, or setToEnd without a distance', () {
    expect(() => SpeedTimeline(10).advance(1), throwsStateError);
    expect(() => SpeedTimeline(10).recede(1), throwsStateError);
    expect(() => SpeedTimeline(10).setToEnd(), throwsStateError);
  });

  test('hasStarted/isFinished/progress are safe defaults before anything else happens', () {
    final timeline = SpeedTimeline(10);

    expect(timeline.hasStarted, isFalse);
    expect(timeline.isFinished, isFalse);
    expect(timeline.progress, 0);
    expect(timeline.duration, isNull);
  });

  test('a fitted distance sets its duration', () {
    final timeline = SpeedTimeline(10)..fit(50);

    expect(timeline.duration, 5);
    expect(timeline.progress, 0);
  });

  test('an effect fits its distance when it starts', () {
    final effect = MoveEffect.by(
      offset: .new(30, 40),
      timeline: .speed(10),
    );

    final scene = SpatialNode(children: [effect]).mount();
    expect(effect.timeline.duration, isNull);

    scene.update(0);
    expect(effect.timeline.duration, 5);
  });

  test('measures after the mount-time state the effect computes', () {
    final node = SpatialNode(position: .zero);
    final scene = node.mount();
    final effect = MoveEffect.to(
      destination: .new(30, 40),
      timeline: .speed(10),
    ); // Distance 50.

    node.add(effect);
    expect(effect.timeline.duration, isNull); // Not yet mounted, so not yet started.

    scene.update(0); // Flushes the mount, snapshotting the offset, then ticks once.
    expect(effect.timeline.duration, 5);
    expect(effect.timeline.progress, 0);
  });

  test('finishes instantly when the measured distance is 0', () {
    final timeline = SpeedTimeline(10);
    final effect = MoveEffect.by(offset: .zero, timeline: timeline);
    final scene = SpatialNode(children: [effect]).mount();

    scene.update(1);
    expect(timeline.duration, 0);
    expect(timeline.isFinished, isTrue);
    expect(timeline.progress, 1);
    expect(effect.isFinished, isTrue);
  });

  test('fits once; setToStart() does not re-measure', () {
    final effect = _MutableDistanceEffect(10, timeline: .speed(10));
    final timeline = effect.timeline;
    effect.mount();

    effect.update(0.5);
    expect(timeline.progress, 0.5);

    timeline.setToStart();
    expect(timeline.progress, 0);

    effect.distance = 20; // Ignored: measure() is never called again.
    effect.update(1);
    expect(timeline.progress, 1); // Finished after 1s, not halfway through 20/10 = 2s.
  });

  test('fits once; receding past the start does not re-measure', () {
    final effect = _MutableDistanceEffect(10, timeline: .speed(10));
    final timeline = effect.timeline;
    effect.mount();

    effect.update(1);
    expect(timeline.recede(1.5), 0.5); // Only 1s of progress to give back.

    effect.distance = 20; // Ignored: measure() is never called again.
    timeline.advance(1);
    expect(timeline.progress, 1); // Finished after 1s, not halfway through 20/10 = 2s.
  });

  test('nests inside repeat, sequence, and infinite timelines', () {
    for (final timeline in [
      Timeline.repeat(.speed(10), 2),
      Timeline.sequence([.speed(10), .duration(1)]),
      Timeline.infinite(.speed(10)),
    ]) {
      final effect = MoveEffect.by(offset: .new(6, 8), timeline: timeline);
      final scene = SpatialNode(children: [effect]).mount();

      scene.update(1.5);
      expect(timeline.progress, 0.5, reason: '$timeline');
    }
  });

  test('cannot be nested inside roundtrip: its duration is unknown at construction', () {
    expect(
      () => RoundtripTimeline(SpeedTimeline(10)),
      throwsAssertionError,
    );
  });
}
