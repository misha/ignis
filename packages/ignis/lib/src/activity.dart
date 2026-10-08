// SPDX-AI-Disclosure: none

part of 'core.dart';

/// A bitmap indicating what kinds of activity an entity or component responds to.
///
/// Entities and components may be separately instrumented to respond to updates and renders.
extension type const Activity(int bits) {
  /// Nothing.
  static const none = Activity(0);

  /// Runs [Entity.update].
  static const update = Activity(1);

  /// Runs [Entity.render].
  static const render = Activity(2);

  /// Participates in all activities: [update] and [render].
  static const all = Activity(3);

  Activity operator |(Activity other) => Activity(bits | other.bits);

  Activity operator &(Activity other) => Activity(bits & other.bits);

  Activity operator ~() => Activity(~bits & all.bits);

  /// Whether this includes [update].
  bool get updates => (bits & update.bits) != 0;

  /// Whether this includes [render].
  bool get renders => (bits & render.bits) != 0;
}
