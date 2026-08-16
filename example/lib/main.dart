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

class GameNode extends Node {
  final shape = ShapeNode(
    shape: .square(100),
    anchor: .center,
    paint: .new()..color = Colors.blue,
  );

  GameNode() {
    Unwatch? unwatchResize;

    onMount(() {
      unwatchResize = scene.onResize((size) {
        shape.position.setFrom(size / 2);
      });
    });

    onUnmount(() {
      unwatchResize?.call();
    });

    add(shape);
  }

  @override
  void tick(double dt) {
    shape.angle += pi / 4 * dt;
  }
}
