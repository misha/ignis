import 'dart:async';
import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';
import 'package:image/image.dart' as img;

/// Advances a GIF recording, running after [frame] is captured and before the
/// next frame is pumped.
typedef GoldenScript = FutureOr<void> Function(int frame);

const _GUTTER = 2;
final _GUTTER_COLOR = img.ColorRgb8(68, 68, 68);

Future<void> expectGolden(
  WidgetTester tester,
  String goldenFile,
  Node node, {
  double width = 100,
  double height = 100,
  Color color = const Color(0xFFFFFFFF),
  double dt = 0,
  DebugMode? debug,
}) async {
  assert(dt >= 0, 'dt cannot be negative.');
  final key = GlobalKey();
  Ignis.debug = Debug();
  Ignis.debug.mode = debug;

  await tester.pumpWidget(
    Center(
      child: RepaintBoundary(
        key: key,
        child: SizedBox(
          width: width,
          height: height,
          child: SceneWidget(
            node.mount(),
            color: color,
          ),
        ),
      ),
    ),
  );

  if (dt > 0) await tester.pump(Duration(milliseconds: (dt * 1000).round()));
  await expectLater(find.byKey(key), matchesGoldenFile(goldenFile));
}

/// Records [frames] frames of [node], each [dt] seconds apart, into a golden
/// filmstrip PNG compared pixel-exact, plus an animated GIF beside it for
/// playback review. [goldenFile] names the GIF; the strip is its .png sibling.
Future<void> expectGoldenGif(
  WidgetTester tester,
  String goldenFile,
  Node node, {
  int frames = 10,
  double dt = 0.125,
  double width = 100,
  double height = 100,
  Color color = const Color(0xFFFFFFFF),
  DebugMode? debug,
  GoldenScript? onFrame,
}) async {
  assert(frames > 1, 'A GIF needs at least two frames.');
  assert(dt > 0, 'dt must be positive.');
  assert(goldenFile.endsWith('.gif'), 'A GIF golden must end in .gif.');
  final key = GlobalKey();
  Ignis.debug = Debug();
  Ignis.debug.mode = debug;

  await tester.pumpWidget(
    Center(
      child: RepaintBoundary(
        key: key,
        child: SizedBox(
          width: width,
          height: height,
          child: SceneWidget(
            node.mount(),
            color: color,
          ),
        ),
      ),
    ),
  );

  final boundary = tester.renderObject<RenderRepaintBoundary>(find.byKey(key));
  final captures = <img.Image>[];

  for (var frame = 0; frame < frames; frame++) {
    final capture = await tester.binding.runAsync(() async {
      final image = await boundary.toImage();
      final data = await image.toByteData(format: .rawRgba);

      return img.Image.fromBytes(
        width: image.width,
        height: image.height,
        bytes: data!.buffer,
        order: .rgba,
      );
    });

    captures.add(capture!);

    if (frame < frames - 1) {
      await onFrame?.call(frame);
      await tester.pump(Duration(milliseconds: (dt * 1000).round()));
    }
  }

  final stripBytes = img.encodePng(_stripOf(captures));
  final gifBytes = _encodeGif(captures, (dt * 100).round());
  final stripFile = goldenFile.replaceFirst('.gif', '.png');
  final comparator = goldenFileComparator as LocalFileComparator;

  if (autoUpdateGoldenFiles) {
    await tester.binding.runAsync(() async {
      await comparator.update(Uri.parse(stripFile), stripBytes);
      await comparator.update(Uri.parse(goldenFile), gifBytes);
    });

    return;
  }

  final master = File.fromUri(comparator.basedir.resolveUri(Uri.parse(stripFile)));

  if (!master.existsSync()) {
    fail('Golden "$stripFile" does not exist. Run with --update-goldens to create it.');
  }

  final expected = master.readAsBytesSync();

  if (_sameBytes(stripBytes, expected)) {
    final gif = File.fromUri(comparator.basedir.resolveUri(Uri.parse(goldenFile)));
    if (gif.existsSync() && _sameBytes(gifBytes, gif.readAsBytesSync())) return;
    fail('Golden "$goldenFile" is stale beside a matching strip. Run with --update-goldens.');
  }

  _failStrip(comparator, goldenFile, captures.first.width, stripBytes, gifBytes, expected);
}

bool _sameBytes(Uint8List a, Uint8List b) {
  if (a.length != b.length) return false;

  for (var i = 0; i < a.length; i++) {
    if (a[i] != b[i]) return false;
  }

  return true;
}

/// Lays [captures] side by side on a gutter-colored ground, one reviewable
/// image for the whole timeline.
img.Image _stripOf(List<img.Image> captures) {
  final width = captures.first.width;
  final strip = img.Image(
    width: _GUTTER + captures.length * (width + _GUTTER),
    height: captures.first.height + 2 * _GUTTER,
  );

  img.fill(strip, color: _GUTTER_COLOR);

  for (final (index, capture) in captures.indexed) {
    img.compositeImage(
      strip,
      capture,
      dstX: _GUTTER + index * (width + _GUTTER),
      dstY: _GUTTER,
    );
  }

  return strip;
}

/// Encodes [captures] as an animated GIF holding each frame [duration]
/// hundredths of a second.
Uint8List _encodeGif(List<img.Image> captures, int duration) {
  final encoder = img.GifEncoder(
    quantizerType: .octree,
    dither: .none,
  );

  for (final capture in captures) {
    encoder.addFrame(capture, duration: duration);
  }

  return encoder.finish()!;
}

/// Fails on a strip mismatch, writing the actual strip and GIF plus a
/// magenta-marked diff strip into failures/.
Never _failStrip(
  LocalFileComparator comparator,
  String golden,
  int frameWidth,
  Uint8List actualBytes,
  Uint8List gifBytes,
  Uint8List expectedBytes,
) {
  final actual = img.decodePng(actualBytes)!;
  final expected = img.decodePng(expectedBytes)!;
  final base = Uri.parse(golden).pathSegments.last.replaceFirst('.gif', '');
  final failures = Directory.fromUri(comparator.basedir.resolve('failures'))
    ..createSync(recursive: true);

  File('${failures.path}/${base}_actual.png').writeAsBytesSync(actualBytes);
  File('${failures.path}/${base}_actual.gif').writeAsBytesSync(gifBytes);

  if (expected.width != actual.width || expected.height != actual.height) {
    fail(
      'Golden "$golden": expected a ${expected.width}x${expected.height} strip, '
      'rendered ${actual.width}x${actual.height}.',
    );
  }

  final diff = img.Image.from(actual);
  final differing = <int>{};

  for (final pixel in actual) {
    final other = expected.getPixel(pixel.x, pixel.y);

    if (pixel.r == other.r && //
        pixel.g == other.g &&
        pixel.b == other.b &&
        pixel.a == other.a) {
      continue;
    }

    differing.add((pixel.x - _GUTTER) ~/ (frameWidth + _GUTTER));
    diff.setPixelRgb(pixel.x, pixel.y, 255, 0, 255);
  }

  if (differing.isEmpty) {
    fail('Golden "$golden": pixels match but the encoded strip bytes differ.');
  }

  File('${failures.path}/${base}_diff.png').writeAsBytesSync(img.encodePng(diff));

  fail(
    'Golden "$golden": frames ${differing.toList()..sort()} differ. '
    'Artifacts written to ${failures.path}.',
  );
}

/// Asserts [condition] eventually holds, failing with [reason] if it never does.
Future<void> expectEventually(bool Function() condition, String reason) async {
  final deadline = DateTime.now().add(const Duration(seconds: 1));

  while (!condition()) {
    if (DateTime.now().isAfter(deadline)) fail(reason);
    await Future.delayed(const Duration(milliseconds: 5));
  }
}

/// Asserts the color channels of [actual] are within [tolerance] of [expected].
void expectColor(Color actual, Color expected, {double tolerance = 0.02}) {
  expect((actual.r - expected.r).abs(), lessThan(tolerance), reason: '$actual vs $expected');
  expect((actual.g - expected.g).abs(), lessThan(tolerance), reason: '$actual vs $expected');
  expect((actual.b - expected.b).abs(), lessThan(tolerance), reason: '$actual vs $expected');
}
