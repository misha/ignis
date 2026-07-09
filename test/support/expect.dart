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
  bool debug = true,
}) async {
  final key = GlobalKey();

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
            debug: debug,
          ),
        ),
      ),
    ),
  );

  await expectLater(find.byKey(key), matchesGoldenFile(goldenFile));
}
