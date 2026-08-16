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
    final game = useMemoized(() {
      return GameNode();
    });

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
    // A declaration, matched by position. This ShapeNode is rebuilt on every
    // pass and thrown away again - the one already standing here is what
    // survives. Keyed on _SIZE, so editing that replaces it; drop the key and
    // the square keeps whatever size it was born with.
    final square = add(
      ShapeNode(
        shape: .square(_SIZE),
        anchor: .center,
      ),
      [_SIZE],
    );

    // Build runs on every pass, so editing _COLOR does persist.
    square.paint.color = _COLOR;

    // Signals subscribed in a pass are owned by it, and re-subscribed by the
    // next one. No bookkeeping.
    onSceneResize((size) {
      square.position.setFrom(size / 2);
    });

    tick << (dt) {
      square.angle += _SPIN * dt;
    };

    // Delete this block and save: the dot is truncated away and detached, and
    // its tick stops.
    //
    // Now add a declaration *above* it and save: this one shifts down a
    // position, finds the square's slot instead of its own, and gets replaced.
    // That is what positional identity costs.
    final dot = add(
      ShapeNode(
        shape: .circle(10),
        anchor: .center,
        paint: .new()..color = Colors.white,
      ),
    );

    tick << (dt) {
      phase += _ORBIT_SPEED * dt;

      dot.position.setValues(
        square.position.x + cos(phase) * _ORBIT,
        square.position.y + sin(phase) * _ORBIT,
      );
    };

    super.build();
  }
}
