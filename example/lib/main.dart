import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ignis/ignis.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Without this the scene still reloads, it just reloads all of it. With it,
  // only the nodes whose file you edited are rebuilt.
  final sources = LocalSources();
  Ignis.sources = sources;
  await sources.start();

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
const _COLOR = Colors.green;
const _SPIN = pi / 4;
const _ORBIT = 90.0;
const _ORBIT_SPEED = 1.0;

/// The probe. Every constant above and every closure below is meant to be
/// edited while the app is running.
class GameNode extends Node {
  double phase = 0;

  @override
  void build() {
    // Editing _SIZE works now. A reload destroys everything this build made
    // and runs it again, so the constructor argument is re-evaluated exactly
    // like the statement below it. Nothing is preserved, nothing is matched,
    // and add hands back the node it was given.
    final square = add(
      ShapeNode(
        shape: .square(_SIZE),
        anchor: .center,
      ),
    );

    // Build runs on every pass, so editing _COLOR does persist.
    square.paint.color = _COLOR;

    // Signals subscribed in a pass are owned by it, and re-subscribed by the
    // next one. No bookkeeping.
    onSceneResize((size) {
      square.position.setFrom(size / 2);
    });

    onUpdate((dt) {
      square.angle += _SPIN * dt;
    });

    // Delete this block and save: the dot goes with it. Insert a declaration
    // above it and save: nothing shifts, because nothing is being matched up.
    //
    // The cost is the other way round now. `phase` survives a reload because
    // it is a field on this node, which nobody rebuilt - but anything held by
    // a node this build *made* is gone, because it was made again.
    final dot = add(
      ShapeNode(
        shape: .circle(10),
        anchor: .center,
        paint: .new()..color = Colors.white,
      ),
    );

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
