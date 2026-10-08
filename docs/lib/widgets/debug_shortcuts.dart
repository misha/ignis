import 'package:flutter/foundation.dart';
import 'package:ignis/ignis.dart';

/// One wireframe as the header reads it.
typedef Wireframe = ({String label, String color, bool draws});

/// The wireframes the site drives, each with the digit that toggles it and the
/// color the engine strokes it in, in the order the header reads them.
///
/// Each key asks for a bare digit, so the browser keeps the shortcuts it builds
/// on ctrl and meta.
final _WIREFRAMES = [
  (
    label: 'spatial',
    mode: DebugMode.spatial,
    key: const KeyPress(.digit1, control: false, meta: false),
    color: _css(Ignis.debug.spatialPaint),
  ),
  (
    label: 'collision',
    mode: DebugMode.collision,
    key: const KeyPress(.digit2, control: false, meta: false),
    color: _css(Ignis.debug.collisionPaint),
  ),
  (
    label: 'input',
    mode: DebugMode.input,
    key: const KeyPress(.digit3, control: false, meta: false),
    color: _css(Ignis.debug.inputPaint),
  ),
  (
    label: 'layout',
    mode: DebugMode.layout,
    key: const KeyPress(.digit4, control: false, meta: false),
    color: _css(Ignis.debug.layoutPaint),
  ),
];

String _css(Paint paint) {
  final rgb = paint.color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0')}';
}

/// The engine's debug overlay, on the digits.
///
/// [DebugControlsNode] uses F1 to F4, which browsers claim, so the site takes
/// 1 to 4 in the same order. [Ignis.debug] is global, so one press answers for
/// every demo on the page.
abstract final class DebugShortcuts {
  /// Every wireframe the header names, or null until a demo comes up.
  static final wireframes = ValueNotifier<List<Wireframe>?>(null);

  /// Toggles the wireframe the header draws [index]th, and reports it.
  static void toggle(int index) {
    Ignis.debug.toggle(_WIREFRAMES[index].mode);
    _report();
  }

  static void _report() {
    wireframes.value = [
      for (final wireframe in _WIREFRAMES)
        (
          label: wireframe.label,
          color: wireframe.color,
          draws: Ignis.debug.draws(wireframe.mode),
        ),
    ];
  }
}

/// Binds the [DebugShortcuts] for the scene it is in, which every demo adds.
final class DebugShortcutsNode extends Node {
  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        Ignis.controls.bind(this, 0, matchers: {_WIREFRAMES[0].key});
        Ignis.controls.bind(this, 1, matchers: {_WIREFRAMES[1].key});
        Ignis.controls.bind(this, 2, matchers: {_WIREFRAMES[2].key});
        Ignis.controls.bind(this, 3, matchers: {_WIREFRAMES[3].key});
        DebugShortcuts._report();

      case Destroy():
        Ignis.controls.release(this);

      case Control(:final action):
        if (action is! int) break;
        DebugShortcuts.toggle(action);
    }
  }
}
