import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/images.dart';

void main() {
  test('loads sheets in order and starts with the first sheet', () async {
    final first = Spritesheet(await solidImage(8, 4, RED), size: .all(4));
    final second = Spritesheet(await solidImage(6, 6, BLUE), size: .all(2));
    final node = SpriteNode.split(sheets: [first, second]);
    node.mount();

    expect(node.sheets, 2);
    expect(node.sheet, same(first));
    expect((node.width, node.height), (4.0, 4.0));
  });

  test('play switches the active sheet and frame', () async {
    final first = Spritesheet(await solidImage(8, 4, RED), size: .all(4));
    final second = Spritesheet(await solidImage(6, 6, BLUE), size: .all(2));
    final node = SpriteNode.split(sheets: [first, second]);

    node.play(
      sheet: 1,
      row: 2,
      column: 1,
    );

    expect(node.sheet, same(second));
    expect(node.frame, 7);

    node.mount();

    expect(node.sheet, same(second));
    expect(node.frame, 7);
  });

  test("width and height default to the first sheet's native size", () async {
    final sheet = Spritesheet(await solidImage(8, 4, RED), size: .all(4));
    final node = SpriteNode(sheet: sheet);

    node.mount();

    expect((node.width, node.height), (4.0, 4.0));
  });

  test('size follows the active sheet', () async {
    final first = Spritesheet(await solidImage(8, 4, RED), size: .all(4));
    final second = Spritesheet(await solidImage(6, 6, BLUE), size: .all(2));
    final node = SpriteNode.split(sheets: [first, second]);

    expect(node.size, Vector2.all(4));

    node.play(sheet: 1);

    expect(node.size, Vector2.all(2));
  });

  test('renders the active sheet', () async {
    final first = Spritesheet(await solidImage(1, 1, RED));
    final second = Spritesheet(await solidImage(1, 1, BLUE));
    final node = SpriteNode.split(sheets: [first, second]);
    node.mount();

    var image = await renderImage(node, node.width.ceil(), node.height.ceil());
    expect(await pixelAt(image, 0, 0), RED);

    node.play(sheet: 1);

    image = await renderImage(node, node.width.ceil(), node.height.ceil());
    expect(await pixelAt(image, 0, 0), BLUE);
  });

  test('renders the selected row and column', () async {
    final sheet = Spritesheet(
      await pixelImage([
        [RED, GREEN],
        [BLUE, WHITE],
      ]),
      size: .all(1),
    );

    final node = SpriteNode(sheet: sheet);
    node.mount();
    node.play(row: 1, column: 1);

    expect(node.frame, 3);
    final image = await renderImage(node, node.width.ceil(), node.height.ceil());
    expect(await pixelAt(image, 0, 0), WHITE);
  });

  test('reassemble re-resolves every sheet, not just the active one', () async {
    addTearDown(Ignis.cache.clear);

    Ignis.cache
      ..add('first.png', await solidImage(8, 4, RED))
      ..add('second.png', await solidImage(6, 6, BLUE));

    final node = SpriteNode.split(
      sheets: [
        Spritesheet.asset('first.png', .all(4)),
        Spritesheet.asset('second.png', .all(2)),
      ],
    );

    // Twice as wide, on the sheet the sprite is not playing.
    Ignis.cache.add('second.png', await solidImage(12, 6, BLUE));

    node.reassemble();
    node.play(sheet: 1);

    expect(node.sheet.columns, 6);
  });

  test('split asserts at least one sheet', () {
    expect(() => SpriteNode.split(sheets: []), throwsAssertionError);
  });

  test('does not detach once finished, by default', () async {
    final a = Node();
    final sheet = Spritesheet(await solidImage(8, 4, RED), size: .all(4));
    final node = SpriteNode(sheet: sheet, fps: 2, loop: false);
    a.add(node);
    final scene = a.mount();

    scene.update(1);
    expect(node.isFinished, isTrue);

    scene.update(0);
    expect(a.children, [node]);
  });

  test('detaches itself once finished, when cleanup is true', () async {
    final a = Node();
    final sheet = Spritesheet(await solidImage(8, 4, RED), size: .all(4));
    final node = SpriteNode(sheet: sheet, fps: 2, loop: false, cleanup: true);
    a.add(node);
    final scene = a.mount();

    scene.update(1);
    expect(node.isFinished, isTrue);
    expect(a.children, [node]); // Still pending.

    scene.update(0);
    expect(a.children, isEmpty);
  });

  test('ignores cleanup while looping, since a looping sprite never finishes', () async {
    final a = Node();
    final sheet = Spritesheet(await solidImage(8, 4, RED), size: .all(4));
    final node = SpriteNode(sheet: sheet, fps: 2, cleanup: true);
    a.add(node);
    final scene = a.mount();

    scene.update(10);
    expect(node.isFinished, isFalse);
    expect(a.children, [node]);
  });
}
