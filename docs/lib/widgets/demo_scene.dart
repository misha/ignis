import 'package:flutter/widgets.dart';
import 'package:ignis/ignis.dart';

import 'colors.dart';
import 'debug_shortcuts.dart';

const DEMO_SIZE = Vector2.all(125);

final Map<String, Future<void>> _loads = {};

Future<void> _load(Iterable<String> assets) {
  return Future.wait([
    for (final asset in assets)
      if (!Ignis.cache.contains(asset))
        _loads[asset] ??= Preload.run(
          loaders: [ImageLoader()],
          paths: [asset],
        ),
  ]);
}

class DemoScene extends StatefulWidget {
  /// Builds the root entity. Called once, after [assets] land.
  final Entity Function() builder;

  /// The asset keys this scene reads out of the cache.
  final List<String> assets;

  const DemoScene({
    required this.builder,
    this.assets = const [],
    super.key,
  });
  @override
  State<DemoScene> createState() => _DemoSceneState();
}

class _DemoSceneState extends State<DemoScene> {
  Scene? scene;

  @override
  void initState() {
    super.initState();

    _load(widget.assets).then((_) {
      if (!mounted) return;

      setState(() {
        DebugShortcuts.attach();
        scene = Scene(widget.builder());
      });
    });
  }

  @override
  Widget build(context) {
    final scene = this.scene;

    if (scene == null) {
      return const ColoredBox(color: INK);
    }

    final stage = FittedBox(
      child: SizedBox(
        width: DEMO_SIZE.x,
        height: DEMO_SIZE.y,
        child: SceneWidget(
          scene,
          color: INK,
          autofocus: false,
        ),
      ),
    );

    return Directionality(
      textDirection: .ltr,
      child: ColoredBox(
        color: INK,
        child: stage,
      ),
    );
  }
}
