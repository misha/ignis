import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/theme.dart';
import 'package:jaspr_flutter_embed/jaspr_flutter_embed.dart';

// Flutter is only imported on the web, since the server cannot import it, and
// deferred so it does not block hydration of the rest of the page.
@Import.onWeb('../widgets/demo_view.dart', show: [#DemoView])
import 'scene_demo.imports.dart' deferred as demo_view;

/// How large every demo is, in pixels. Demos are square.
///
/// The view is sized by its host element rather than by `ViewConstraints`,
/// which leave the unnamed axis unbounded - and a scene handed an unbounded
/// axis has no size to lay out against.
const DEMO_EMBEDDED_SIZE = 250.0;

/// One live scene, embedded in the page.
///
/// Every `<Demo name="..."/>` slot with a scene behind it resolves to this, and
/// the name is all that separates one from another: the client half looks it up
/// in its own registry once Flutter is up.
@client
class SceneDemo extends StatelessComponent {
  final String name;

  const SceneDemo({
    required this.name,
    super.key,
  });

  @override
  Component build(BuildContext context) {
    return div(classes: 'demo-scene', [
      FlutterEmbedView.deferred(
        styles: Styles(
          width: DEMO_EMBEDDED_SIZE.px,
          height: DEMO_EMBEDDED_SIZE.px,
        ),
        loadLibrary: demo_view.loadLibrary(),
        builder: () {
          return demo_view.DemoView(name: name);
        },
        loader: div(classes: 'demo-loader', [.text('Loading the scene…')]),
      ),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.demo-scene').styles(
      width: DEMO_EMBEDDED_SIZE.px,
      height: DEMO_EMBEDDED_SIZE.px,
      radius: .circular(0.5.rem),
      overflow: .hidden,
    ),
    css('.demo-loader').styles(
      display: .flex,
      height: 100.percent,
      justifyContent: .center,
      alignItems: .center,
      color: ContentColors.text,
    ),
  ];
}
