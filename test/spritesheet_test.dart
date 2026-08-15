import 'dart:ui';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'support/images.dart';

void main() {
  setUp(() {
    Ignis.cache.clear();
  });

  test('uses the whole image as one frame by default', () async {
    final image = await solidImage(8, 4);
    final sheet = Spritesheet(image);

    expect(sheet.image, same(image));
    expect(sheet.size, Vector2(8, 4));
    expect(sheet.rows, 1);
    expect(sheet.columns, 1);
    expect(sheet.frames, 1);
    expect(sheet[0], const Rect.fromLTWH(0, 0, 8, 4));
  });

  test('caches frame rectangles in row-major order', () async {
    final sheet = Spritesheet(await solidImage(4, 6), size: .all(2));

    expect(sheet.rows, 3);
    expect(sheet.columns, 2);
    expect(sheet.frames, 6);
    expect(
      [
        for (var frame = 0; frame < sheet.frames; frame += 1) //
          sheet[frame],
      ],
      const [
        Rect.fromLTWH(0, 0, 2, 2),
        Rect.fromLTWH(2, 0, 2, 2),
        Rect.fromLTWH(0, 2, 2, 2),
        Rect.fromLTWH(2, 2, 2, 2),
        Rect.fromLTWH(0, 4, 2, 2),
        Rect.fromLTWH(2, 4, 2, 2),
      ],
    );
  });

  test('clones the supplied frame size', () async {
    final size = MVector2.all(2);
    final sheet = Spritesheet(await solidImage(4, 4), size: size);

    size.splat(1);

    expect(sheet.size, Vector2.all(2));
  });

  test('creates a sheet from an asset', () async {
    const key = 'spritesheet';
    final image = await solidImage(4, 4);
    Ignis.cache.add(key, image);
    final size = MVector2.all(2);
    final sheet = Spritesheet.asset(key, size: size);
    size.splat(4);

    expect(sheet.image, same(image));
    expect(sheet.size, Vector2.all(2));
    expect(sheet.frames, 4);
  });

  test('requires positive finite frame dimensions', () async {
    final image = await solidImage(4, 4);

    expect(() => Spritesheet(image, size: .new(0, 2)), throwsArgumentError);
    expect(() => Spritesheet(image, size: .new(2, double.infinity)), throwsArgumentError);
  });

  test('requires frame dimensions to divide the image evenly', () async {
    final image = await solidImage(4, 4);

    expect(() => Spritesheet(image, size: .new(3, 2)), throwsArgumentError);
    expect(() => Spritesheet(image, size: .new(2, 3)), throwsArgumentError);
  });

  test('rejects frame indexes outside the sheet', () async {
    final sheet = Spritesheet(await solidImage(4, 4), size: .all(2));

    expect(() => sheet[-1], throwsRangeError);
    expect(() => sheet[sheet.frames], throwsRangeError);
  });
}
