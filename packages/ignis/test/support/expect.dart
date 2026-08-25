import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'colors.dart';

Future<void> expectGolden(
  WidgetTester tester,
  String goldenFile,
  Node node, {
  double width = 100,
  double height = 100,
  Color color = WHITE,
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
