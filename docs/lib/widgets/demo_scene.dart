import 'package:flutter/widgets.dart';
import 'package:ignis/ignis.dart';

/// The ground every demo scene is painted on, matching the site's dark surface.
///
/// Code blocks are dark in both modes, since the highlighter bakes its colors
/// in at build time. Demos follow them, so the two never disagree on a page.
const DEMO_BACKGROUND = Color(0xFF1B1815);

/// The square every demo scene is laid out in, in scene units.
///
/// The stage is a fixed size and is fitted to whatever box the page gives it,
/// so a demo looks the same wherever it is shown and however large that box
/// turns out to be. Scale is the page's business, and stays out of demo code.
const DEMO_SIZE = Vector2.all(125);

/// Loads in flight or already finished, so a sheet two demos share is read once.
final Map<String, Future<void>> _loads = {};

Future<void> _load(Iterable<String> assets) {
  return Future.wait([
    for (final asset in assets)
      if (!Ignis.cache.contains(asset))
        _loads[asset] ??= Preload.run(loaders: [.image()], paths: [asset]),
  ]);
}

/// The line a demo prints, standing in the corner of its own scene.
///
/// A signal fires and leaves nothing on screen, so a demo about signals has
/// nothing to show. Printing is what makes it a demo at all - and the scene is
/// where it belongs, rather than in a panel the page has to make room for.
class DemoLog extends TextNode {
  DemoLog() : super(style: _print(.muted));

  /// Shows [line], in [color] where one event should stand apart from another.
  void call(String line, [LogColor color = .muted]) {
    text = line;
    style = _print(color);
  }
}

/// What a demo can print in, so a call says which color it means.
///
/// A scene draws where no stylesheet reaches, so every one of these is stated
/// rather than inherited, and each is picked to read on the demo's own ground.
enum LogColor {
  muted(Color(0xFF9A9186)),
  white(Color(0xFFEDE7DD)),
  orange(Color(0xFFC78F30)),
  blue(Color(0xFF7FA6C4)),
  green(Color(0xFF8FB07A)),
  red(Color(0xFFC4756A));

  final Color value;

  const LogColor(this.value);
}

/// How large a printed line is drawn, in scene units.
const _PRINT_SIZE = 7.0;

/// The site's own mono, registered with Flutter in `pubspec.yaml`.
///
/// The fallback is what canvaskit downloads for itself, and is here because an
/// unmatched family draws no glyphs at all rather than substituting one.
TextStyle _print(LogColor color) {
  return TextStyle(
    color: color.value,
    fontFamily: 'iA Writer Mono',
    fontFamilyFallback: const ['Roboto'],
    fontSize: _PRINT_SIZE,
  );
}

/// A scene, mounted once the assets it draws from are in [Ignis.cache].
///
/// [Spritesheet.asset] and its like read the cache synchronously, so a scene
/// that builds too early throws. Every demo goes through here to be sure it
/// doesn't.
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

    _load(widget.assets).then((_) {
      if (!mounted) return;

      setState(() {
        scene = widget.builder().mount();
      });
    });
  }

  @override
  Widget build(context) {
    final scene = this.scene;
    if (scene == null) return const ColoredBox(color: DEMO_BACKGROUND);

    final stage = FittedBox(
      child: SizedBox.square(
        dimension: DEMO_SIZE.x,
        // Autofocus is off on purpose. A scene embedded in a page of prose
        // must not take focus as it mounts, or it drags the reader with it.
        child: SceneWidget(
          scene,
          color: DEMO_BACKGROUND,
          autofocus: false,
        ),
      ),
    );

    // An embedded view is mounted bare, with no `WidgetsApp` above it, so a
    // widget that resolves a start or end edge has no direction to resolve it
    // against unless one is declared here.
    return Directionality(
      textDirection: TextDirection.ltr,
      child: ColoredBox(color: DEMO_BACKGROUND, child: stage),
    );
  }
}
