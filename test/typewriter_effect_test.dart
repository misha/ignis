import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

void main() {
  test('types to, one character at a time', () {
    final node = TextNode(text: '');
    final scene = node.mount();

    node.add(
      TypewriterEffect(
        to: 'Hello',
        controller: .new(duration: 5),
        cleanup: true,
      ),
    );

    scene.update(1);
    expect(node.text, 'H');

    scene.update(1);
    expect(node.text, 'He');

    scene.update(1);
    expect(node.text, 'Hel');

    scene.update(1);
    expect(node.text, 'Hell');

    scene.update(1);
    expect(node.text, 'Hello');

    scene.update(0); // Flush the self-detach.
    expect(node.children, isEmpty);
  });

  test('resumes typing from an existing prefix', () {
    final node = TextNode(text: '');
    final scene = node.mount();

    node.add(
      TypewriterEffect(
        from: 'He',
        to: 'Hello',
        controller: .new(duration: 3),
      ),
    );

    scene.update(1);
    expect(node.text, 'Hel');

    scene.update(1);
    expect(node.text, 'Hell');

    scene.update(1);
    expect(node.text, 'Hello');
  });

  test('shows from unchanged when it already equals to', () {
    final node = TextNode(text: '');
    final scene = node.mount();

    node.add(
      TypewriterEffect(
        from: 'Hi',
        to: 'Hi',
        controller: .new(duration: 1),
      ),
    );

    scene.update(0.5);
    expect(node.text, 'Hi');

    scene.update(0.5);
    expect(node.text, 'Hi');
  });

  test('emits onType once per character typed', () {
    final node = TextNode(text: '');
    final scene = node.mount();
    final effect = TypewriterEffect(
      to: 'Hello',
      controller: .new(duration: 5),
    );

    var types = 0;
    effect.onType(() => types += 1);
    node.add(effect);

    scene.update(1);
    expect(types, 1);

    scene.update(1);
    expect(types, 2);
  });

  test('emits onType once per character even when several type in one tick', () {
    final node = TextNode(text: '');
    final scene = node.mount();
    final effect = TypewriterEffect(
      to: 'Hello',
      controller: .new(duration: 5),
    );

    var types = 0;
    effect.onType(() => types += 1);
    node.add(effect);

    scene.update(5);
    expect(types, 5);
  });

  test('re-resolves its target after being remounted elsewhere', () {
    final root = TextNode(text: '');
    final nodeA = TextNode(text: '');
    final nodeB = TextNode(text: '');
    root.addAll([nodeA, nodeB]);
    final scene = root.mount();
    final effect = TypewriterEffect(
      from: 'Hi',
      to: 'Hiya',
      controller: .new(duration: 2),
    );

    nodeA.add(effect);
    scene.update(1);
    expect(nodeA.text, 'Hiy');

    effect.detach();
    scene.update(0); // Flush the detach.
    nodeB.add(effect);
    scene.update(0); // Flush the attach.

    scene.update(1);
    expect(nodeA.text, 'Hiy'); // Unchanged.
    expect(nodeB.text, 'Hiya');
  });
}
