// SPDX-AI-Disclosure: none

part of 'core.dart';

/// A bitmap indicating what kinds of activity a node responds to.
///
/// Nodes may be separately instrumented to respond to updates, renders, and
/// inputs.
extension type const Activity(int bits) {
  /// Nothing.
  static const none = Activity(0);

  /// Runs [Node.update].
  static const update = Activity(1);

  /// Runs [Node.render].
  static const render = Activity(2);

  /// Accepts inputs via [Node.hitTest].
  static const input = Activity(4);

  /// Participates in all activities: [update], [render], and [input].
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
