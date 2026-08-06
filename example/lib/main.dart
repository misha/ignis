import 'package:auris/auris.dart';
import 'package:flutter/material.dart';
import 'package:widgetbook/widgetbook.dart';

import 'stories/bouncing_balls_demo_story.dart';
import 'stories/drag_and_drop_demo_story.dart';
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
          home: Scaffold(
            body: SafeArea(
              minimum: .all(10),
              child: SizedBox.expand(
                child: FittedBox(
                  fit: .contain,
                  child: child,
                ),
              ),
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
                  builder: (context) => const BouncingBallsDemoStory(),
                ),
              ],
            ),
            WidgetbookComponent(
              name: 'Drag and Drop',
              useCases: [
                WidgetbookUseCase(
                  name: 'Default',
                  builder: (context) => const DragAndDropDemoStory(),
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
