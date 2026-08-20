import 'package:ignis/ignis.dart';

/// One wireframe as the header reads it: what to call it, the color the engine
/// is stroking it in, and whether it is drawing.
typedef Wireframe = ({String label, String color, bool draws});

/// The wireframes the site drives, each with the digit that toggles it and the
/// color the engine strokes it in, in the order the header reads them.
///
/// Each key asks for a bare digit, so the browser keeps the shortcuts it builds
/// on ctrl and meta.
final _WIREFRAMES = [
  (
    label: 'transforms',
    mode: DebugMode.transforms,
    key: const KeyPress(.digit1, control: false, meta: false),
    color: _css(Ignis.debug.transformPaint),
  ),
  (
    label: 'collisions',
    mode: DebugMode.collisions,
    key: const KeyPress(.digit2, control: false, meta: false),
    color: _css(Ignis.debug.collisionPaint),
  ),
  (
    label: 'inputs',
    mode: DebugMode.inputs,
    key: const KeyPress(.digit3, control: false, meta: false),
    color: _css(Ignis.debug.inputPaint),
  ),
  (
    label: 'layouts',
    mode: DebugMode.layouts,
    key: const KeyPress(.digit4, control: false, meta: false),
    color: _css(Ignis.debug.layoutPaint),
  ),
];

String _css(Paint paint) {
  final rgb = paint.color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0')}';
}

/// The engine's debug overlay, on the digits, for the site rather than a scene.
///
/// [DebugControlsNode] puts one wireframe on each of F1 to F4, which a browser
/// has spoken for, so the site takes 1 to 4 in the same order. They bind
/// outside every scene, and [Ignis.debug] is global, so one press answers for
/// every demo on the page at once.
abstract final class DebugShortcuts {
  /// Emitted whenever a press changes what the demos draw.
  static final onChange = Signal0();

  static bool _bound = false;

  /// Every wireframe the header names, or null until a demo comes up to draw
  /// any of them.
  static List<Wireframe>? get wireframes {
    if (!_bound) return null;

    return [
      for (final wireframe in _WIREFRAMES)
        (
          label: wireframe.label,
          color: wireframe.color,
          draws: Ignis.debug.draws(wireframe.mode),
        ),
    ];
  }

  /// Toggles the wireframe the header draws [index]th, and reports it.
  static void toggle(int index) {
    Ignis.debug.toggle(_WIREFRAMES[index].mode);
    onChange.emit();
  }

  /// Binds the shortcuts, which every demo asks for as it comes up.
  ///
  /// The first to ask is the one that binds them: a page with no demo has no
  /// engine to take the keys, and nothing to draw over if it did.
  static void install() {
    if (_bound) return;
    _bound = true;

    Ignis.controls.bind(
      (_) => toggle(0),
      matchers: {_WIREFRAMES[0].key},
    );

    Ignis.controls.bind(
      (_) => toggle(1),
      matchers: {_WIREFRAMES[1].key},
    );

    Ignis.controls.bind(
      (_) => toggle(2),
      matchers: {_WIREFRAMES[2].key},
    );

    Ignis.controls.bind(
      (_) => toggle(3),
      matchers: {_WIREFRAMES[3].key},
    );

    onChange.emit();
  }
}
