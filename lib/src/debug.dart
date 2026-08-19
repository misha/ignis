part of 'core.dart';

/// What the debug overlay draws, one mode at a time.
///
/// [Debug]'s methods will cycle through these.
enum DebugMode {
  /// Every wireframe at once.
  all,

  /// Every drawn node's bounds.
  transforms,

  /// Every collider's hitbox.
  collisions,

  /// Every input node's hit area.
  inputs,

  /// Every layout node's box.
  layouts,
}

/// Holds debug settings used across all Ignis scenes.
///
/// Nodes and systems that wish to participate in the a particular debug [mode]
/// should reach directly into [Ignis.debug] when checking if it it's enabled.
class Debug {
  /// The one in use, which is whatever [Ignis.debug] holds.
  ///
  /// A name for it from inside core, where [Ignis] is reachable but reads
  /// oddly: the engine's own render path asks for the debug settings, not for
  /// a global.
  static Debug get instance => Ignis.debug;

  /// What the overlay draws, or null while it draws nothing.
  DebugMode? mode;

  /// Whether the overlay draws at all.
  ///
  /// Every [Node.debugDraw] runs while this is on, whatever [mode] is, so a
  /// drawing of your own shows in every mode there is.
  bool get enabled => mode != null;

  /// What the [DebugMode.transforms] wireframe draws with.
  Paint transformPaint = Paint()
    ..color = const Color(0xFF6F2DBD)
    ..style = .stroke
    ..strokeWidth = 0;

  /// What the [DebugMode.collisions] wireframe draws with.
  Paint collisionPaint = Paint()
    ..color = const Color(0xFFDC4D01)
    ..style = .stroke
    ..strokeWidth = 0;

  /// What the [DebugMode.inputs] wireframe draws with.
  Paint inputPaint = Paint()
    ..color = const Color(0xFF1E90FF)
    ..style = .stroke
    ..strokeWidth = 0;

  /// What the [DebugMode.layouts] wireframe draws with.
  Paint layoutPaint = Paint()
    ..color = const Color(0xFF2DBD6F)
    ..style = .stroke
    ..strokeWidth = 0;

  /// Whether [mode] draws, which [DebugMode.all] answers for every one.
  bool draws(DebugMode mode) => this.mode == .all || this.mode == mode;

  /// Steps to the next mode, or to the first from off.
  void next() {
    const modes = DebugMode.values;
    final current = mode;
    mode = current == null ? modes.first : modes[(current.index + 1) % modes.length];
  }

  /// Steps back a mode, or to the last from off.
  void previous() {
    const modes = DebugMode.values;
    final current = mode;
    mode = current == null ? modes.last : modes[(current.index - 1) % modes.length];
  }
}
