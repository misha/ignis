import 'package:jaspr/dom.dart';
import 'package:jaspr/jaspr.dart';
import 'package:jaspr_content/theme.dart';

import '../theme.dart';

@Import.onWeb('../widgets/debug_shortcuts.dart', show: [#DebugShortcuts])
import 'debug_panel.imports.dart' deferred as debug_shortcuts;

typedef _Wireframe = ({String label, String color, bool draws});

@client
class DebugPanel extends StatefulComponent {
  const DebugPanel({super.key});

  @override
  State<DebugPanel> createState() => _DebugPanelState();

  @css
  static List<StyleRule> get styles => [
    // The package's header is a flex row of a title and an items group, so a
    // panel between the two is measured against the header itself rather than
    // against either of them.
    css('.docs .header').styles(position: .relative()),
    css('.docs .header .debug', [
      css('&').styles(
        display: .flex,
        position: .absolute(left: 50.percent, top: 50.percent),
        userSelect: .none,
        transform: .translate(x: (-50).percent, y: (-50).percent),
        alignItems: .center,
        gap: .column(0.375.rem),
        fontFamily: ContentTheme.currentCodeFont,
        fontSize: 0.6875.rem,
      ),
      // A button inherits neither face nor size, so the row's are restated
      // here rather than left to the parent.
      css('.debug-mode', [
        css('&').styles(
          padding: .zero,
          border: .none,
          cursor: .pointer,
          fontFamily: ContentTheme.currentCodeFont,
          fontSize: 0.6875.rem,
          fontWeight: .w400,
          backgroundColor: Colors.transparent,
        ),
        // Weight and a rule only. The color is the wireframe's own and says
        // whether it draws, so hovering must not touch it.
        css('&:hover').styles(
          fontWeight: .w700,
          textDecoration: const TextDecoration(line: .underline),
        ),
        css('&.on').styles(fontWeight: .w700),
      ]),
      css('.debug-slash').styles(color: IgnisColors.dim),
    ]),
    // The title and the items close on the middle well before this, and the
    // panel would be read over them.
    css.media(MediaQuery.screen(maxWidth: 64.rem), [
      css('.docs .header .debug').styles(display: .none),
    ]),
  ];
}

class _DebugPanelState extends State<DebugPanel> {
  void Function()? _unwatch;

  /// What the shortcuts last left the demos drawing.
  List<_Wireframe>? wireframes;

  @override
  void initState() {
    super.initState();
    if (!kIsWeb) return;

    debug_shortcuts.loadLibrary().then((_) {
      if (!mounted) return;

      // Read once behind the subscription, in case a demo came up and bound
      // the keys while the library was still loading.
      _unwatch = debug_shortcuts.DebugShortcuts.onChange.watch(_read);
      _read();
    });
  }

  @override
  void dispose() {
    _unwatch?.call();
    super.dispose();
  }

  void _read() {
    setState(() {
      wireframes = debug_shortcuts.DebugShortcuts.wireframes;
    });
  }

  @override
  Component build(BuildContext context) {
    final wireframes = this.wireframes;
    if (wireframes == null) return .fragment([]);

    return div(classes: 'debug', [
      for (final (index, wireframe) in wireframes.indexed) ...[
        if (index > 0) span(classes: 'debug-slash', [.text('/')]),
        _mode(wireframe, index),
      ],
    ]);
  }

  Component _mode(_Wireframe wireframe, int index) {
    return button(
      classes: wireframe.draws ? 'debug-mode on' : 'debug-mode',
      styles: Styles(color: wireframe.draws ? Color(wireframe.color) : IgnisColors.grey),
      attributes: {'title': 'Toggle with ${index + 1}'},
      onClick: () => debug_shortcuts.DebugShortcuts.toggle(index),
      [.text(wireframe.label)],
    );
  }
}
