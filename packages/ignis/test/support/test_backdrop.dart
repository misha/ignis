import 'package:ignis/ignis.dart';

/// A fully knobbed backdrop that records what it was driven with and dims
/// what it covers.
final class TestBackdrop extends Backdrop {
  final applies = <double>[];

  @override
  final Activity running;

  @override
  final Activity settled;

  TestBackdrop({
    Activity? running,
    Activity? settled,
  }) : running = running ?? .render,
       settled = settled ?? .render;

  @override
  void apply(progress, covered) {
    applies.add(progress);
    covered.opacity = 1 - progress;
  }
}
