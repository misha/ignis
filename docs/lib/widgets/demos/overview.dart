import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ignis/ignis.dart';

import '../demo_scene.dart';

/// The scene the overview opens on.
final Map<String, Widget Function()> overviewDemos = {
  'spinner': () => DemoScene(builder: _SpinnerEntity.new),
};

/// A square turning in place, at the middle of the stage.
class _SpinnerEntity extends Entity {
  _SpinnerEntity() : super(position: DEMO_SIZE / 2);

  // demo on spinner
  late Entity square;

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        square = add(
          Entity(
            components: [
              ShapeComponent(
                shape: .square(40),
                anchor: .center,
                paint: Paint()..color = Colors.orange,
              ),
            ],
          ),
        );

      case Update(:final dt):
        square.angle += pi / 4 * dt;
    }
  }
  // demo off
}
