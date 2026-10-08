import 'dart:math';

import 'package:flutter/material.dart';
import 'package:ignis/ignis.dart';

import '../demo_scene.dart';

/// The scene the overview opens on.
final Map<String, Widget Function()> overviewDemos = {
  'spinner': () => DemoScene(builder: _SpinnerNode.new),
};

/// A square turning in place, at the middle of the stage.
class _SpinnerNode extends SpatialNode {
  _SpinnerNode() : super(position: DEMO_SIZE / 2);

  // demo on spinner
  late ShapeNode square;

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        square = add(
          ShapeNode(
            shape: .square(40),
            anchor: .center,
            paint: Paint()..color = Colors.orange,
          ),
        );

      case Update(:final dt):
        square.angle += pi / 4 * dt;
    }
  }
  // demo off
}
