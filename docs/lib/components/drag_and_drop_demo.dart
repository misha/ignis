import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/theme.dart';
import 'package:jaspr_flutter_embed/jaspr_flutter_embed.dart';

// Flutter is only imported on the web, since the server cannot import it, and
// deferred so it does not block hydration of the rest of the page.
@Import.onWeb('../widgets/drag_and_drop.dart', show: [#DragAndDropWidget])
import 'drag_and_drop_demo.imports.dart' deferred as drag_and_drop;

/// The drag-and-drop scene, with its status line rendered as page HTML.
///
/// The status is Jaspr state driven by a signal inside the scene, which is the
/// point of the demo: the page and the engine share Dart state directly.
@client
class DragAndDropDemo extends StatefulComponent {
  const DragAndDropDemo({super.key});

  @override
  State<DragAndDropDemo> createState() => DragAndDropDemoState();
}

class DragAndDropDemoState extends State<DragAndDropDemo> {
  String status = 'Drag the square onto a zone.';

  @override
  Component build(BuildContext context) {
    return div(classes: 'demo-solo', [
      FlutterEmbedView.deferred(
        // Sized for the 300x300 board this demo draws, rather than for the
        // square the `<Demo/>` slots use.
        constraints: ViewConstraints(
          minWidth: 300,
          maxWidth: double.infinity,
          minHeight: 320,
          maxHeight: 320,
        ),
        loadLibrary: drag_and_drop.loadLibrary(),
        builder: () {
          return drag_and_drop.DragAndDropWidget(
            onStatus: (value) {
              setState(() {
                status = value;
              });
            },
          );
        },
        loader: div(classes: 'demo-loader', [.text('Loading the scene…')]),
      ),
      p(classes: 'demo-status', [.text(status)]),
    ]);
  }

  @css
  static List<StyleRule> get styles => [
    css('.demo-solo').styles(
      margin: .only(top: 1.5.rem, bottom: 1.5.rem),
      radius: .circular(0.5.rem),
      overflow: .hidden,
    ),
    css('.demo-status').styles(
      padding: .all(0.75.rem),
      margin: .zero,
      color: ContentColors.text,
      textAlign: .center,
      fontSize: 0.9.rem,
    ),
  ];
}
