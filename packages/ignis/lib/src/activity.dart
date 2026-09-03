// SPDX-AI-Disclosure: ai-generated

part of 'core.dart';

/// What a node takes part in, as bits: ticking, rendering, and hearing input.
extension type const Activity(int bits) {
  /// Nothing.
  static const none = Activity(0);

  /// Running [Node.tick] callbacks and updating children.
  static const update = Activity(1);

  /// Running [Node.draw] callbacks and rendering children.
  static const render = Activity(2);

  /// Hit testing and answering binds.
  static const input = Activity(4);

  /// All three.
  static const all = Activity(7);

  Activity operator |(Activity other) => Activity(bits | other.bits);

  Activity operator &(Activity other) => Activity(bits & other.bits);

  Activity operator ~() => Activity(~bits & all.bits);

  /// Whether this includes [update].
  bool get updates => (bits & update.bits) != 0;

  /// Whether this includes [render].
  bool get renders => (bits & render.bits) != 0;

  /// Whether this includes [input].
  bool get inputs => (bits & input.bits) != 0;
}
