import 'package:flutter/painting.dart' show TextAlign, TextDirection, TextStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/colors.dart';
import 'support/images.dart';

void main() {
  test('setting text writes through to the painter', () {
    final node = TextNode(text: 'I');
    node.mount();
    node.text = 'Ignis';
    expect(node.painter.plainText, 'Ignis');
  });

  test('setting style writes through to the painter', () {
    final node = TextNode(text: 'I');
    node.mount();
    const style = TextStyle(color: RED, fontSize: 30);
    node.style = style;
    expect(node.painter.text?.style, style);
  });

  test('setting textAlign writes through to the painter', () {
    final node = TextNode(text: 'I');
    node.mount();
    node.textAlign = .center;
    expect(node.painter.textAlign, TextAlign.center);
  });

  test('setting textDirection writes through to the painter', () {
    final node = TextNode(text: 'I');
    node.mount();
    node.textDirection = .rtl;
    expect(node.painter.textDirection, TextDirection.rtl);
  });

  test('updates its layout when text changes', () {
    final node = TextNode(text: 'I');
    node.mount();
    node.layout();

    final initialWidth = node.width;
    node.text = 'Ignis';
    node.layout();

    expect(node.width, greaterThan(initialWidth));
  });

  test('renders styled text', () async {
    final node = TextNode(
      text: 'I',
      style: const TextStyle(
        color: RED,
        fontSize: 30,
      ),
    );

    node.mount();
    node.layout();

    final image = await renderImage(node, node.width.ceil(), node.height.ceil());
    final pixels = await pixelsOf(image);
    expect(pixels, contains(isNot(0)));
  });
}
