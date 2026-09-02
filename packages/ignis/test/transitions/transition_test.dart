import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  late TransitionGroupNode<String> incoming;
  late TransitionGroupNode<String> outgoing;

  setUp(() {
    incoming = TransitionGroupNode(name: 'incoming');
    outgoing = TransitionGroupNode(name: 'outgoing');
  });

  test('a plain fade leaves the outgoing side alone', () {
    FadeTransition().apply(0.5, .zero, incoming: incoming, outgoing: outgoing);

    expect(incoming.opacity, 0.5);
    expect(outgoing.opacity, 1);
  });

  test('a crossfade dips both sides', () {
    FadeTransition(crossFade: true).apply(0.5, .zero, incoming: incoming, outgoing: outgoing);

    expect(incoming.opacity, 0.5);
    expect(outgoing.opacity, 0.5);
  });

  test('a slide shoves the outgoing side ahead of the incoming one', () {
    SlideTransition().apply(0.25, .all(100), incoming: incoming, outgoing: outgoing);

    expect(incoming.position.x, 0);
    expect(incoming.position.y, 75);
    expect(outgoing.position.x, 0);
    expect(outgoing.position.y, -25);
  });

  test('a curtain trades the sides at its swap point', () {
    final curtain = CurtainTransition();

    curtain.apply(0.4, .zero, incoming: incoming, outgoing: outgoing);
    expect(incoming.opacity, 0);
    expect(outgoing.opacity, 1);

    curtain.apply(0.5, .zero, incoming: incoming, outgoing: outgoing);
    expect(incoming.opacity, 1);
    expect(outgoing.opacity, 0);
  });

  test('a wipe trades the sides at its swap point', () {
    final wipe = WipeTransition(swapAt: 0.8);

    wipe.apply(0.7, .zero, incoming: incoming, outgoing: outgoing);
    expect(incoming.opacity, 0);
    expect(outgoing.opacity, 1);

    wipe.apply(0.8, .zero, incoming: incoming, outgoing: outgoing);
    expect(incoming.opacity, 1);
    expect(outgoing.opacity, 0);
  });

  test('a cut hides the outgoing side at once', () {
    CutTransition().apply(1, .zero, incoming: incoming, outgoing: outgoing);

    expect(incoming.opacity, 1);
    expect(outgoing.opacity, 0);
  });
}
