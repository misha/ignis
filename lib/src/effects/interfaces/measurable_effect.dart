/// An effect with a well-defined "distance".
///
/// Effects that implement this interface becomes compatible for composition
/// with `SpeedEffectController`.
abstract interface class MeasurableEffect {
  /// This effect's "distance" from minimum progress to maximum progress.
  double measure();
}
