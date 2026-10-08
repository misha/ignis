// SPDX-AI-Disclosure: none

part of 'core.dart';

/// What the debug overlay draws, one wireframe at a time.
enum DebugMode {
  /// The origin of every `Transform` and the bounds of all `Geometry`.
  spatial,
}

/// Holds debug settings used across all Ignis scenes.
///
/// Components and systems that wish to participate in a particular debug [mode]
/// should reach directly into [Ignis.debug] when checking if it's enabled.
class Debug {
  /// The settings in use.
  ///
  /// Named for use inside core, where reading [Ignis] reads oddly.
  static Debug get instance => Ignis.debug;

  /// What the overlay draws, or null to draw no wireframe at all.
  DebugMode? mode;

  /// Whether the overlay draws at all.
  ///
  /// Every `debugRender` runs while this is on, whatever [mode] is.
  bool get enabled => mode != null;

  /// What the [DebugMode.spatial] wireframe draws with.
  Paint spatialPaint = Paint()
    ..color = const Color(0xFF6F2DBD)
    ..style = .stroke
    ..strokeWidth = 0;

  /// What the wireframe in [mode] draws with, the origin cross included.
  Paint get paint => switch (mode) {
    .spatial || null => spatialPaint,
  };

  /// Whether [mode] is the one drawing.
  bool draws(DebugMode mode) => this.mode == mode;

  /// Draws [mode], or clears the overlay if it was already the one drawing.
  void toggle(DebugMode mode) {
    this.mode = this.mode == mode ? null : mode;
  }
}
