import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  late TransitionGroupNode<String> incoming;
  late TransitionGroupNode<String> outgoing;

  setUp(() {
    incoming = TransitionGroupNode(name: 'in');
    outgoing = TransitionGroupNode(name: 'out');
    TransitionNode<String>(children: [incoming, outgoing]).mount().resize(100, 100);
  });

  test('a plain fade leaves the outgoing side alone', () {
    FadeTransition().apply(0.5, incoming, outgoing);

    expect(incoming.opacity, 0.5);
    expect(outgoing.opacity, 1);
  });

  test('a crossfade dips both sides', () {
    FadeTransition(crossFade: true).apply(0.5, incoming, outgoing);

    expect(incoming.opacity, 0.5);
    expect(outgoing.opacity, 0.5);
  });

  test('a slide shoves the outgoing side ahead of the incoming one', () {
    SlideTransition().apply(0.25, incoming, outgoing);

    expect(incoming.position.x, 0);
    expect(incoming.position.y, 75);
    expect(outgoing.position.x, 0);
    expect(outgoing.position.y, -25);
  });

  test('a curtain trades the sides at its swap point', () {
    final curtain = CurtainTransition(veil: ShapeNode());

    curtain.apply(0.4, incoming, outgoing);
    expect(incoming.opacity, 0);
    expect(outgoing.opacity, 1);

    curtain.apply(0.5, incoming, outgoing);
    expect(incoming.opacity, 1);
    expect(outgoing.opacity, 0);
  });

  test('a curtain fades its veil to full at the swap point', () {
    final curtain = CurtainTransition(veil: ShapeNode());

    curtain.apply(0.25, incoming, outgoing);
    expect(curtain.chrome.opacity, 0.5);

    curtain.apply(0.5, incoming, outgoing);
    expect(curtain.chrome.opacity, 1);

    curtain.apply(0.75, incoming, outgoing);
    expect(curtain.chrome.opacity, 0.5);
  });

  test('a wipe trades the sides at its swap point', () {
    final wipe = WipeTransition(panel: ShapeNode(), swapAt: 0.8);

    wipe.apply(0.7, incoming, outgoing);
    expect(incoming.opacity, 0);
    expect(outgoing.opacity, 1);

    wipe.apply(0.8, incoming, outgoing);
    expect(incoming.opacity, 1);
    expect(outgoing.opacity, 0);
  });

  test('a wipe sweeps its panel in from the leading edge and out the trailing one', () {
    final wipe = WipeTransition(panel: ShapeNode());

    wipe.apply(0.25, incoming, outgoing);
    expect(wipe.chrome.position.x, -50);

    wipe.apply(0.75, incoming, outgoing);
    expect(wipe.chrome.position.x, 50);
  });

  test('a cut hides the outgoing side at once', () {
    CutTransition().apply(1, incoming, outgoing);

    expect(incoming.opacity, 1);
    expect(outgoing.opacity, 0);
  });
}
