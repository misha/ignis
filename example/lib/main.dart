import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ignis/ignis.dart';

void main() {
  runApp(const LiveReloadApp());
}

class LiveReloadApp extends StatelessWidget {
  const LiveReloadApp({super.key});

  @override
  Widget build(context) {
    return const MaterialApp(
      title: 'Live Reload',
      home: GamePage(),
    );
  }
}

class GamePage extends HookWidget {
  const GamePage({super.key});

  @override
  Widget build(context) {
    final game = useMemoized(() => GameNode());

    return Scaffold(
      body: SceneWidget(game.mount()),
    );
  }
}

const _SIZE = 100.0;
const _COLOR = Colors.blue;
const _SPIN = pi / 4;
const _ORBIT = 90.0;
const _ORBIT_SPEED = 1.0;

/// The probe. Every constant above and every closure below is meant to be
/// edited while the app is running.
class GameNode extends Node {
  double phase = 0;

  @override
  void build() {
    // Construction is state, so a reload preserves it.
    // Thus, changing _SIZE has no effect on the existing square.
    final square = child(() {
      return ShapeNode(
        shape: .square(_SIZE),
        anchor: .center,
      );
    });

    // Build runs on every pass, so editing _COLOR does persist.
    square.paint.color = _COLOR;

    onSceneResize((size) {
      square.position.setFrom(size / 2);
    });

    onUpdate((dt) {
      square.angle += _SPIN * dt;
    });

    // Delete this block and save: the dot detaches and its tick stops.
    final dot = child(() {
      return ShapeNode(
        shape: .circle(10),
        anchor: .center,
        paint: .new()..color = Colors.white,
      );
    });

    onUpdate((dt) {
      phase += _ORBIT_SPEED * dt;

      dot.position.setValues(
        square.position.x + cos(phase) * _ORBIT,
        square.position.y + sin(phase) * _ORBIT,
      );
    });

    super.build();
  }
}
