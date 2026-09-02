import 'package:ignis/ignis.dart';

/// A fully knobbed transition that records what it was driven with.
final class TestTransition extends Transition {
  final applies = <double>[];

  @override
  final Node? chrome;

  TestTransition({
    this.chrome,
    Timeline? timeline,
  }) : super(timeline: timeline ?? .duration(1));

  @override
  void apply(progress, _, _) {
    applies.add(progress);
  }
}
