import 'package:flutter/painting.dart' show TextAlign, TextDirection, TextStyle;
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/images.dart';

void main() {
  test('repaints changed text without an explicit layout', () async {
    final text = TextComponent(text: 'I');
    final entity = Entity(components: [text]);
    Scene(entity);
    await renderImage(entity, 40, 20);

    text.text = 'Ignis';
    await renderImage(entity, 40, 20);
    expect(text.painter.plainText, 'Ignis');
  });

  test('setting text reaches the painter', () {
    final text = TextComponent(text: 'I');
    Scene(Entity(components: [text]));
    text.text = 'Ignis';

    expect(text.text, 'Ignis');
    expect(text.painter.plainText, 'Ignis');
  });

  test('setting style reaches the painter', () {
    final text = TextComponent(text: 'I');
    Scene(Entity(components: [text]));
    const style = TextStyle(color: RED, fontSize: 30);
    text.style = style;
    final expected = TextComponent.DEFAULT_STYLE.merge(style);

    expect(text.style, expected);
    expect(text.painter.text?.style, expected);
  });

  test('setting textAlign reaches the painter', () {
    final text = TextComponent(text: 'I');
    Scene(Entity(components: [text]));
    text.textAlign = .center;

    expect(text.textAlign, TextAlign.center);
    expect(text.painter.textAlign, TextAlign.center);
  });

  test('setting textDirection reaches the painter', () {
    final text = TextComponent(text: 'I');
    Scene(Entity(components: [text]));
    text.textDirection = .rtl;

    expect(text.textDirection, TextDirection.rtl);
    expect(text.painter.textDirection, TextDirection.rtl);
  });

  test('updates its size when text changes', () {
    final text = TextComponent(text: 'I');
    Scene(Entity(components: [text]));

    final initialWidth = text.width;
    text.text = 'Ignis';

    expect(text.width, greaterThan(initialWidth));
  });

  test('reports a zero size until it builds', () {
    final text = TextComponent(text: 'Ignis');
    expect(text.size, Vector2.zero, reason: 'nothing to measure with yet');
  });

  test('measures its text on demand', () {
    final text = TextComponent(text: 'Ignis');
    Scene(Entity(components: [text]));

    expect(text.size, isNot(Vector2.zero));
  });

  test('refuses a shape, since its text sizes it', () {
    final text = TextComponent(text: 'Ignis');
    expect(() => text.shape = .square(10), throwsUnsupportedError);
  });
}
