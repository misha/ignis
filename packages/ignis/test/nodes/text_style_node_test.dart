import 'package:flutter/painting.dart' show FontWeight, TextStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';

const BASE = TextStyle(fontFamily: 'Mono', fontSize: 7);

void main() {
  test('takes the style in effect at its ancestor', () {
    final node = TextNode(text: 'I');
    TextStyleNode(style: BASE, children: [node]).mount();

    expect(node.style.fontFamily, 'Mono');
    expect(node.style.fontSize, 7);
    expect(node.style.color, WHITE, reason: 'the default style sits under every chain');
  });

  test('extends that style with its own', () {
    final node = TextNode(
      text: 'I',
      style: const TextStyle(color: RED),
    );

    TextStyleNode(style: BASE, children: [node]).mount();

    expect(node.style.fontFamily, 'Mono');
    expect(node.style.color, RED);
  });

  test('replaces that style when its own does not inherit', () {
    const own = TextStyle(inherit: false, fontSize: 30);
    final node = TextNode(text: 'I', style: own);
    TextStyleNode(style: BASE, children: [node]).mount();

    expect(node.style, own);
  });

  test('takes the nearest style, extended by every outer one', () {
    final node = TextNode(text: 'I');
    final inner = TextStyleNode(
      style: const TextStyle(fontSize: 12, fontWeight: .bold),
      children: [node],
    );

    TextStyleNode(style: BASE, children: [inner]).mount();

    expect(node.style.fontFamily, 'Mono');
    expect(node.style.fontSize, 12);
    expect(node.style.fontWeight, FontWeight.bold);
  });

  test('reaches through a node that holds no style', () {
    final node = TextNode(text: 'I');
    final group = Node(children: [node]);

    TextStyleNode(style: BASE, children: [group]).mount();

    expect(node.style.fontFamily, 'Mono');
  });

  test('follows the style as it changes', () {
    final node = TextNode(text: 'I');
    final holder = TextStyleNode(style: BASE, children: [node]);

    holder.mount();
    node.layout(.unbounded());
    holder.style = const TextStyle(fontSize: 9);
    node.layout(.unbounded());

    expect(node.painter.text?.style?.fontSize, 9);
  });

  test('follows an outer style as it changes', () {
    final node = TextNode(text: 'I');
    final inner = TextStyleNode(
      style: const TextStyle(fontWeight: .bold),
      children: [node],
    );

    final outer = TextStyleNode(style: BASE, children: [inner]);
    outer.mount();
    node.layout(.unbounded());
    outer.style = const TextStyle(fontSize: 9);
    node.layout(.unbounded());

    expect(node.painter.text?.style?.fontSize, 9);
    expect(node.painter.text?.style?.fontWeight, FontWeight.bold);
  });

  test('falls back to the default style with nothing above', () {
    final node = TextNode(text: 'I');
    node.mount();

    expect(node.style, TextNode.DEFAULT_STYLE);
  });

  test('goes back to the inherited style when its own is cleared', () {
    final node = TextNode(
      text: 'I',
      style: const TextStyle(color: RED),
    );
    TextStyleNode(style: BASE, children: [node]).mount();
    node.style = null;

    expect(node.style.color, WHITE);
    expect(node.style.fontFamily, 'Mono');
  });

  test('reports its own style with nothing above, even before it mounts', () {
    final holder = TextStyleNode(style: BASE);

    expect(holder.style, BASE);
  });
}
