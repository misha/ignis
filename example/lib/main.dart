import 'package:flutter/widgets.dart';
import 'package:widgetbook/widgetbook.dart';

import 'stories/bouncing_balls.dart';
import 'stories/snake_story.dart';

void main() {
  runApp(const ExampleWidgetbook());
}

class ExampleWidgetbook extends StatelessWidget {
  const ExampleWidgetbook();

  @override
  Widget build(context) {
    return Widgetbook.material(
      directories: [
        WidgetbookComponent(
          name: 'BouncingBalls',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (context) => const BouncingBalls(),
            ),
          ],
        ),
        WidgetbookComponent(
          name: 'Snake',
          useCases: [
            WidgetbookUseCase(
              name: 'Default',
              builder: (context) => const SnakeGameWidget(),
            ),
          ],
        ),
      ],
    );
  }
}
