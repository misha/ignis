// SPDX-AI-Disclosure: none

/// An effect with a well-defined "distance".
///
/// Effects that implement this interface can be paced by `Timeline.speed`.
abstract interface class MeasurableEffect {
  /// This effect's "distance" from minimum progress to maximum progress.
  double measure();
}
