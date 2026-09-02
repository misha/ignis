// SPDX-AI-Disclosure: ai-generated

/// Determines how a `RouterNode` treats the current route on a push.
enum Backdrop {
  /// Keeps updating and painting. Input is still blocked.
  live,

  /// Keeps painting, stops updating.
  frozen,

  /// Stops painting or updating entirely.
  hidden,
}
