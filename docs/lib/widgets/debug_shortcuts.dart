import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:ignis/ignis.dart';

/// One wireframe as the header reads it.
typedef Wireframe = ({String label, String color, bool draws});

/// The wireframes the site drives, each with the digit that toggles it and the
/// color the engine strokes it in, in the order the header reads them.
final _WIREFRAMES = [
  (
    label: 'spatial',
    mode: DebugMode.spatial,
    key: LogicalKeyboardKey.digit1,
    color: _css(Ignis.debug.spatialPaint),
  ),
];

String _css(Paint paint) {
  final rgb = paint.color.toARGB32() & 0xFFFFFF;
  return '#${rgb.toRadixString(16).padLeft(6, '0')}';
}

/// The engine's debug overlay, on the digits.
///
/// [Ignis.debug] is global, so one press answers for every demo on the page.
abstract final class DebugShortcuts {
  /// Every wireframe the header names, or null until a demo comes up.
  static final wireframes = ValueNotifier<List<Wireframe>?>(null);

  static bool _attached = false;

  /// Listens for the digits, once, and reports the wireframes.
  static void attach() {
    if (!_attached) {
      _attached = true;
      HardwareKeyboard.instance.addHandler(_handle);
    }

    _report();
  }

  /// Toggles the wireframe the header draws [index]th, and reports it.
  static void toggle(int index) {
    Ignis.debug.toggle(_WIREFRAMES[index].mode);
    _report();
  }

  /// Takes a bare digit, so the browser keeps the shortcuts it builds on ctrl
  /// and meta.
  static bool _handle(KeyEvent event) {
    if (event is! KeyDownEvent) return false;
    final keyboard = HardwareKeyboard.instance;
    if (keyboard.isControlPressed || keyboard.isMetaPressed) return false;

    for (var i = 0; i < _WIREFRAMES.length; i += 1) {
      if (event.logicalKey != _WIREFRAMES[i].key) continue;
      toggle(i);
      return true;
    }

    return false;
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
