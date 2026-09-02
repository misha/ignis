import 'package:ignis/ignis.dart';

/// A fully knobbed transition that records what it was driven with.
final class TestTransition extends TransitionEffect {
  @override
  final double swapAt;

  final applies = <double>[];
  int builds = 0;
  void Function(TestTransition transition)? onBuild;

  TestTransition(
    super.to,
    super.from, {
    EffectController? controller,
    this.swapAt = 0.5,
    this.onBuild,
    super.cleanup,
    super.priority,
    super.enabled,
  }) : super(controller: controller ?? .duration(1));

  @override
  void build() {
    super.build();
    builds += 1;
    onBuild?.call(this);
  }

  @override
  void apply(double progress) {
    applies.add(progress);
  }
}
