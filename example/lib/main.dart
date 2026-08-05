import 'package:auris/auris.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'stories/bouncing_balls.dart';
import 'stories/snake_game_story.dart';

void main() {
  runApp(const ExampleWidgetbook());
}

class ExampleWidgetbook extends StatelessWidget {
  const ExampleWidgetbook();

  @override
  Widget build(context) {
    return Widgetbook.material(
      lightTheme: AurisTheme.light(),
      darkTheme: AurisTheme.dark(),
      appBuilder: (context, child) {
        return MaterialApp(
          theme: Theme.of(context),
          home: Material(
            child: SizedBox.expand(
              child: FittedBox(child: child),
            ),
          ),
        );
      },
      directories: [
        WidgetbookFolder(
          name: 'Demos',
          children: [
            WidgetbookComponent(
              name: 'Bouncing Balls',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const BouncingBalls(),
                ),
              ],
            ),
          ],
        ),
        WidgetbookFolder(
          name: 'Games',
          children: [
            WidgetbookComponent(
              name: 'Snake',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const SnakeGameStory(),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }
}
