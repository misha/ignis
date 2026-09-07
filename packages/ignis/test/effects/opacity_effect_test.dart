import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  const EPSILON = 1e-6;

  test('fades the nearest opacity owner in from nothing to whole', () {
    final host = OpacityNode(
      opacity: 0,
      children: [OpacityEffect.fadeIn(timeline: .duration(1))],
    );

    final scene = host.mount();

    scene.update(0.25);
    expect(host.opacity, closeTo(0.25, EPSILON));

    scene.update(0.75);
    expect(host.opacity, closeTo(1, EPSILON));
  });

  test('fades the nearest opacity owner out from whole to nothing', () {
    final host = OpacityNode(
      children: [OpacityEffect.fadeOut(timeline: .duration(1))],
    );

    final scene = host.mount();

    scene.update(0.5);
    expect(host.opacity, closeTo(0.5, EPSILON));

    scene.update(0.5);
    expect(host.opacity, closeTo(0, EPSILON));
  });

  test('takes the closest opacity owner above it, not an outer one', () {
    final inner = OpacityNode(
      children: [OpacityEffect.fadeOut(timeline: .duration(1))],
    );

    final outer = OpacityNode(children: [inner]);
    outer.mount().update(0.5);

    expect(inner.opacity, closeTo(0.5, EPSILON));
    expect(outer.opacity, 1);
  });
}
