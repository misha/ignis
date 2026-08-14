import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/colors.dart';
import '../support/expect.dart';

void main() {
  testWidgets(
    'renders styled text',
    (tester) => expectGolden(
      tester,
      'goldens/text_label.png',
      TextNode(
        text: 'Ignis',
        style: const TextStyle(color: BLACK, fontSize: 24),
        anchor: .center,
        position: .all(50),
      ),
    ),
  );
}
