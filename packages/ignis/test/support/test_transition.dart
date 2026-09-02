import 'package:ignis/ignis.dart';

/// A fully knobbed transition that records what it was driven with.
final class TestTransition extends Transition {
  final applies = <double>[];
  final chromes = <double>[];

  TestTransition({EffectController? controller}) //
    : super(controller: controller ?? .duration(1));

  @override
  void apply(
    double progress,
    Vector2 size, {
    required TransitionGroupNode incoming,
    required TransitionGroupNode outgoing,
  }) {
    applies.add(progress);
  }

  @override
  void paintChrome(Canvas canvas, double progress, Vector2 size) {
    chromes.add(progress);
  }
}
