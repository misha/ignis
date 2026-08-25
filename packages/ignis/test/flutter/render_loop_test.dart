import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/src/flutter/render_loop.dart';

void main() {
  testWidgets('does not tick before being started', (tester) async {
    final dts = <double>[];
    final loop = RenderLoop(dts.add);

    await tester.pump(const Duration(milliseconds: 16));

    expect(dts, isEmpty);
    loop.dispose();
  });

  testWidgets('reports zero elapsed time on the first tick', (tester) async {
    final dts = <double>[];
    final loop = RenderLoop(dts.add)..start();

    await tester.pump(const Duration(milliseconds: 16));

    expect(dts, [0]);
    loop.dispose();
  });

  testWidgets('reports elapsed seconds between subsequent ticks', (tester) async {
    final dts = <double>[];
    final loop = RenderLoop(dts.add)..start();

    await tester.pump(const Duration(milliseconds: 16));
    await tester.pump(const Duration(milliseconds: 32));

    expect(dts, [0, closeTo(0.032, 0.0001)]);
    loop.dispose();
  });

  testWidgets('stops ticking once stopped, resetting elapsed time', (tester) async {
    final dts = <double>[];
    final loop = RenderLoop(dts.add)..start();

    await tester.pump(const Duration(milliseconds: 16));
    loop.stop();
    await tester.pump(const Duration(milliseconds: 16));
    expect(dts, [0]);

    loop.start();
    await tester.pump(const Duration(milliseconds: 16));
    expect(dts, [0, 0]);
    loop.dispose();
  });
}
