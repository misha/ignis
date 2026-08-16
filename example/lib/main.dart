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

/// The probe. Every constant above and every line below is meant to be edited
/// while the app is running.
class GameNode extends Node {
  @override
  void tick(double dt) {
    // Construction is state, so a reload preserves it. Keying on _SIZE opts
    // back out: editing it builds a new square, and the old one's angle with
    // it. Nothing else about this constructor reloads.
    final square = fuseChild(() {
      return ShapeNode(
        shape: .square(_SIZE),
        anchor: .center,
      );
    }, [_SIZE]);

    // Re-applied by every reassembly, so editing _COLOR is the edit.
    fuseEffect(() {
      square.paint.color = _COLOR;
    });

    fuseSignal1(scene.onResize, (size) {
      square.position.setFrom(size / 2);
    });

    square.angle += _SPIN * dt;

    // Delete this block and save: the dot detaches and stops orbiting.
    final dot = fuseChild(() {
      return ShapeNode(
        shape: .circle(10),
        anchor: .center,
        paint: .new()..color = Colors.white,
      );
    });

    final phase = fuseState(0.0);
    phase.value += _ORBIT_SPEED * dt;

    dot.position.setValues(
      square.position.x + cos(phase.value) * _ORBIT,
      square.position.y + sin(phase.value) * _ORBIT,
    );
  }
}
