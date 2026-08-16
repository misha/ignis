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
    // Construction is state, so a reload preserves it. Keying on _SIZE opts
    // back out: editing it builds a new square, and the old one's angle with
    // it. Nothing else about this constructor reloads.
    final square = fuseChild(
      () => ShapeNode(
        shape: .square(_SIZE),
        anchor: .center,
      ),
      [_SIZE],
    );

    // Re-applied by every pass, so editing _COLOR is the edit.
    fuseEffect(() {
      square.paint.color = _COLOR;
      return null;
    });

    fuseSignal1(scene.onResize, (size) {
      square.position.setFrom(size / 2);
    });

    fuseTick((dt) {
      square.angle += _SPIN * dt;
    });

    // Delete this block and save: the dot detaches and its tick stops.
    final dot = fuseChild(
      () => ShapeNode(
        shape: .circle(10),
        anchor: .center,
        paint: .new()..color = Colors.white,
      ),
    );

    fuseTick((dt) {
      phase += _ORBIT_SPEED * dt;

      dot.position.setValues(
        square.position.x + cos(phase) * _ORBIT,
        square.position.y + sin(phase) * _ORBIT,
      );
    });

    super.build();
  }
}
