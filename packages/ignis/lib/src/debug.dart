part of 'core.dart';

/// What the debug overlay draws, one wireframe at a time.
///
/// [spatial] bounds every spatial node, so it shows the most. The other three
/// each draw one category exactly, as its true shape rather than the box
/// around it.
enum DebugMode {
  /// Every spatial node's bounds.
  spatial,

  /// Every collider's hitbox.
  collision,

  /// Every input node's hit area.
  input,

  /// Every layout node's box.
  layout,
}

/// Holds debug settings used across all Ignis scenes.
///
/// Nodes and systems that wish to participate in a particular debug [mode]
/// should reach directly into [Ignis.debug] when checking if it's enabled.
class Debug {
  /// The one in use, which is whatever [Ignis.debug] holds.
  ///
  /// A name for it from inside core, where [Ignis] is reachable but reads
  /// oddly: the engine's own render path asks for the debug settings, not for
  /// a global.
  static Debug get instance => Ignis.debug;

  /// What the overlay draws, or null to draw no wireframe at all.
  DebugMode? mode;

  /// Whether the overlay draws at all.
  ///
  /// Every [Node.debugDraw] runs while this is on, whatever [mode] is, so a
  /// drawing of your own shows in every mode there is.
  bool get enabled => mode != null;

  /// What the [DebugMode.spatial] wireframe draws with.
  Paint spatialPaint = Paint()
    ..color = const Color(0xFF6F2DBD)
    ..style = .stroke
    ..strokeWidth = 0;

  /// What the [DebugMode.collision] wireframe draws with.
  Paint collisionPaint = Paint()
    ..color = const Color(0xFFDC4D01)
    ..style = .stroke
    ..strokeWidth = 0;

  /// What the [DebugMode.input] wireframe draws with.
  Paint inputPaint = Paint()
    ..color = const Color(0xFF1E90FF)
    ..style = .stroke
    ..strokeWidth = 0;

  /// What the [DebugMode.layout] wireframe draws with.
  Paint layoutPaint = Paint()
    ..color = const Color(0xFF2DBD6F)
    ..style = .stroke
    ..strokeWidth = 0;

  /// What the wireframe in [mode] draws with, the origin cross included.
  Paint get paint => switch (mode) {
    .collision => collisionPaint,
    .input => inputPaint,
    .layout => layoutPaint,
    .spatial || null => spatialPaint,
  };

  /// Whether [mode] is the one drawing.
  bool draws(DebugMode mode) => this.mode == mode;

  /// Draws [mode], or clears the overlay if it was already the one drawing.
  void toggle(DebugMode mode) {
    this.mode = this.mode == mode ? null : mode;
  }
}
