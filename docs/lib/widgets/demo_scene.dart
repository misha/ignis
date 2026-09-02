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

/// The type every demo sets text in, with no color of its own so a caller can
/// give it either a [color] or a [TextStyle.foreground].
const DEMO_TEXT_STYLE = TextStyle(
  fontFamily: 'iA Writer Mono',
  fontFamilyFallback: ['Roboto'],
  fontSize: 7,
);

class DemoLog extends TextNode {
  DemoLog() : super(style: TextStyle(color: GREY));

  void call(String line, [Color color = GREY]) {
    text = line;
    style = TextStyle(color: color);
  }
}

class DemoScene extends StatefulWidget {
  /// Builds the root node. Called once, after [assets] land.
  final Node Function() builder;

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
  Scene<Node>? scene;

  @override
  void initState() {
    super.initState();
    DebugShortcuts.install();

    _load(widget.assets).then((_) {
      if (!mounted) return;

      setState(() {
        scene = TextStyleNode(
          style: DEMO_TEXT_STYLE,
          children: [widget.builder()],
        ).mount();
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
