import 'package:ignis/ignis.dart';

/// A fully knobbed transition that records what it was driven with.
final class TestTransition extends Transition {
  final applies = <double>[];

  final Node Function()? chrome;

  TestTransition({
    this.chrome,
    Timeline? timeline,
    super.incoming,
    super.outgoing,
  }) : super(timeline: timeline ?? .duration(1));

  @override
  Node? buildChrome() => chrome?.call();

  @override
  void apply(progress, _, _, _) {
    applies.add(progress);
  }
}
