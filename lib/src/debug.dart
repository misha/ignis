part of 'core.dart';

/// What the debug overlay draws, as one bit per wireframe.
///
/// The bits combine, so a mode is any set of wireframes at once: [none] holds
/// no wireframe, [all] holds every one, and `transforms | inputs` holds the two
/// it names.
extension type const DebugMode._(int _bits) {
  /// No wireframe at all.
  static const none = DebugMode._(0);

  /// Every drawn node's bounds.
  static const transforms = DebugMode._(1 << 0);

  /// Every collider's hitbox.
  static const collisions = DebugMode._(1 << 1);

  /// Every input node's hit area.
  static const inputs = DebugMode._(1 << 2);

  /// Every layout node's box.
  static const layouts = DebugMode._(1 << 3);

  /// Every wireframe at once.
  static const all = DebugMode._(0xF);

  /// Each wireframe on its own, in bit order.
  static const values = [transforms, collisions, inputs, layouts];

  /// The wireframes of both.
  DebugMode operator |(DebugMode other) => DebugMode._(_bits | other._bits);

  /// The wireframes of this one that [other] leaves out.
  DebugMode operator -(DebugMode other) => DebugMode._(_bits & ~other._bits);

  /// Whether every wireframe of [other] is in this one.
  bool draws(DebugMode other) => _bits & other._bits == other._bits;
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

  /// What the overlay draws, which [DebugMode.none] leaves bare.
  DebugMode mode = .none;

  /// Whether the overlay draws at all.
  ///
  /// Every [Node.debugDraw] runs while this is on, whatever [mode] is, so a
  /// drawing of your own shows in every mode there is.
  bool get enabled => mode != DebugMode.none;

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

  /// Whether [mode] is currently active.
  bool draws(DebugMode mode) => this.mode.draws(mode);

  /// Toggles [mode]'s bits.
  void toggle(DebugMode mode) {
    if (draws(mode)) {
      this.mode -= mode;
    } else {
      this.mode |= mode;
    }
  }
}
