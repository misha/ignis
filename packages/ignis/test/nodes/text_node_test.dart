import 'package:flutter/painting.dart' show TextAlign, TextDirection, TextStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/images.dart';

void main() {
  test('repaints changed text without an explicit layout', () async {
    final node = TextNode(text: 'I');
    node.mount();
    await renderImage(node, 40, 20);

    node.text = 'Ignis';
    await renderImage(node, 40, 20);
    expect(node.painter.plainText, 'Ignis');
  });

  test('setting text reaches the painter on the next reflow', () {
    final node = TextNode(text: 'I');
    node.mount();
    node.text = 'Ignis';

    expect(node.text, 'Ignis');
    node.layout(.unbounded());
    expect(node.painter.plainText, 'Ignis');
  });

  test('setting style reaches the painter on the next reflow', () {
    final node = TextNode(text: 'I');
    node.mount();
    const style = TextStyle(color: RED, fontSize: 30);
    node.style = style;
    final expected = TextNode.DEFAULT_STYLE.merge(style);

    expect(node.style, expected);
    node.layout(.unbounded());
    expect(node.painter.text?.style, expected);
  });

  test('setting textAlign reaches the painter on the next reflow', () {
    final node = TextNode(text: 'I');
    node.mount();
    node.textAlign = .center;

    expect(node.textAlign, TextAlign.center);
    node.layout(.unbounded());
    expect(node.painter.textAlign, TextAlign.center);
  });

  test('setting textDirection reaches the painter on the next reflow', () {
    final node = TextNode(text: 'I');
    node.mount();
    node.textDirection = .rtl;

    expect(node.textDirection, TextDirection.rtl);
    node.layout(.unbounded());
    expect(node.painter.textDirection, TextDirection.rtl);
  });

  test('a remount replaces the painter and keeps the text', () {
    final node = TextNode(text: 'Ignis');
    final scene = node.mount();
    final first = node.painter;

    scene.destroy();
    node.mount();

    expect(node.painter, isNot(same(first)));
    expect(node.text, 'Ignis');
  });

  test('updates its layout when text changes', () {
    final node = TextNode(text: 'I');
    node.mount();
    node.layout(.unbounded());

    final initialWidth = node.width;
    node.text = 'Ignis';
    node.layout(.unbounded());

    expect(node.width, greaterThan(initialWidth));
  });

  test('wraps its text within the available width', () {
    final node = TextNode(text: 'Ignis lays its text out');
    node.mount();

    node.layout(.unbounded());
    final unwrapped = node.size;

    node.layout(.loose(.new(unwrapped.x / 2, double.infinity)));

    expect(node.width, lessThan(unwrapped.x));
    expect(node.height, greaterThan(unwrapped.y));
  });

  test('re-wraps when the constraints change, not just the text', () {
    final node = TextNode(text: 'Ignis lays its text out');
    node.mount();

    node.layout(.unbounded());
    final unwrapped = node.size;

    node.layout(.loose(.new(unwrapped.x / 2, double.infinity)));
    final wrapped = node.size;

    node.layout(.unbounded());
    expect(node.size, unwrapped);
    expect(wrapped.x, lessThan(unwrapped.x));
  });

  test('fills a tight width rather than shrinking to its text', () {
    final node = TextNode(text: 'I');
    node.mount();

    node.layout(.tight(.new(200, 50)));
    expect(node.width, 200);
  });

  test('reports a zero size until it builds', () {
    final node = TextNode(text: 'Ignis');
    expect(node.size, Vector2.zero, reason: 'nothing to measure with yet');
  });

  test('measures its text on demand, without waiting to be laid out', () {
    final node = TextNode(text: 'Ignis');
    node.mount();

    expect(node.size, isNot(Vector2.zero));
  });
}
