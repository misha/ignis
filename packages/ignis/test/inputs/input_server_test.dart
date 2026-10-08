import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';
import 'package:ignis/src/flutter/scene_render_box.dart';

import '../support/test_node.dart';
import '../support/test_sink.dart';

void main() {
  Future<Scene> pumpScene(WidgetTester tester, Iterable<Node> children) async {
    final scene = Node(children: children).mount();
    scene.resize(800, 600);
    await tester.pumpWidget(RenderSceneWidget(scene: scene, addRepaintBoundary: true));
    return scene;
  }

  const settle = Duration(milliseconds: 50);

  testWidgets('a hit fires TapDown', (tester) async {
    final tap = TapInput(shape: .square(20));
    final sink = TestSink([tap]);
    await pumpScene(tester, [sink]);

    await tester.startGesture(const Offset(5, 5));
    await tester.pump(settle);

    expect(sink.of<TapDown>(), hasLength(1));
    expect(sink.of<TapDown>().single.scene, Vector2.all(5));
  });

  testWidgets('a miss fires nothing', (tester) async {
    final tap = TapInput(shape: .square(20));
    final sink = TestSink([tap]);
    await pumpScene(tester, [sink]);

    await tester.startGesture(const Offset(500, 500));
    await tester.pump(settle);

    expect(sink.of<TapDown>(), isEmpty);
  });

  testWidgets('a clean release fires TapUp and Tap', (tester) async {
    final tap = TapInput(shape: .square(20));
    final sink = TestSink([tap]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.up();
    await tester.pump(settle);

    expect(sink.of<TapUp>(), hasLength(1));
    expect(sink.of<Tap>(), hasLength(1));
  });

  testWidgets('isDown tracks the press', (tester) async {
    final tap = TapInput(shape: .square(200));
    await pumpScene(tester, [tap]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await tester.pump(settle);
    expect(tap.isDown, isTrue);

    await gesture.up();
    await tester.pump(settle);
    expect(tap.isDown, isFalse);
  });

  testWidgets('dragging past the slop starts, then updates with the right delta', (tester) async {
    final drag = DragInput(shape: .square(200));
    final sink = TestSink([drag]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    await gesture.up();
    await tester.pump(settle);

    expect(sink.of<DragStart>(), hasLength(1));
    expect(sink.of<DragStart>().single.scene, Vector2.all(5));
    expect(sink.of<DragUpdate>(), isNotEmpty);
    // Flutter reports the down position as the first update's globalPosition,
    // so its delta must come out zero.
    expect(sink.of<DragUpdate>().first.delta, Vector2.zero);
    expect(sink.of<DragUpdate>().last.scene, Vector2(55, 5));
  });

  testWidgets('isDragging tracks the current drag', (tester) async {
    final drag = DragInput(shape: .square(200));
    await pumpScene(tester, [drag]);

    expect(drag.isDragging, isFalse);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    expect(drag.isDragging, isTrue);

    await gesture.up();
    await tester.pump(settle);
    expect(drag.isDragging, isFalse);
  });

  testWidgets('a cancelled drag does not emit DragEnd by default', (tester) async {
    final drag = DragInput(shape: .square(200));
    final sink = TestSink([drag]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    await gesture.cancel();
    await tester.pump(settle);

    expect(sink.of<DragCancel>(), hasLength(1));
    expect(sink.of<DragEnd>(), isEmpty);
  });

  testWidgets('endOnCancel manufactures DragEnd from the last known position', (tester) async {
    final drag = DragInput(shape: .square(200), endOnCancel: true);
    final sink = TestSink([drag]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    await gesture.cancel();
    await tester.pump(settle);

    expect(sink.of<DragCancel>(), hasLength(1));
    expect(sink.of<DragEnd>(), hasLength(1));
    expect(sink.of<DragEnd>().single.details.globalPosition, const Offset(55, 5));
  });

  testWidgets('delta stays correct under a scaling ancestor', (tester) async {
    final drag = DragInput(shape: .square(200));
    final sink = TestSink([drag]);
    final scene = Node(children: [sink]).mount();
    scene.resize(800, 600);

    await tester.pumpWidget(
      Transform.scale(
        scale: 2,
        alignment: .topLeft,
        child: RenderSceneWidget(scene: scene, addRepaintBoundary: true),
      ),
    );

    final gesture = await tester.startGesture(const Offset(10, 10));
    await gesture.moveBy(const Offset(100, 0));
    await gesture.up();
    await tester.pump(settle);

    // 100 units of window movement is 50 units of scene movement at 2x scale.
    expect(sink.of<DragUpdate>().last.delta.x, closeTo(50, 0.001));
  });

  testWidgets('an uncontested drag starts on any movement', (tester) async {
    final drag = DragInput(shape: .square(200));
    final sink = TestSink([drag]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(1, 0));
    await gesture.up();
    await tester.pump(settle);

    // With nothing else contesting this pointer's arena, Flutter's gesture
    // arena resolves the lone recognizer immediately rather than waiting.
    expect(sink.of<DragStart>(), hasLength(1));
  });

  testWidgets('a real drag wins over a contesting tap for the same pointer', (tester) async {
    final tap = TapInput(
      shape: .square(200),
      priority: 1,
      behavior: .translucent,
    );

    final drag = DragInput(shape: .square(200));
    final sink = TestSink([tap, drag]);
    await pumpScene(tester, [sink]);

    // tap is translucent, so both nodes are offered the down event and their
    // recognizers contest the same pointer's arena.
    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    await gesture.up();
    await tester.pump(settle);

    expect(sink.of<DragStart>(), hasLength(1));
    expect(sink.of<TapUp>(), isEmpty);

    // A contested tap holds its own down until kPressTimeout, so one resolved
    // this fast never announced itself and has nothing to take back.
    expect(sink.of<TapDown>(), isEmpty);
    expect(sink.of<TapCancel>(), isEmpty);
  });

  testWidgets('upOnCancel manufactures TapUp from where the pointer went down', (tester) async {
    final tap = TapInput(shape: .square(200), upOnCancel: true);
    final sink = TestSink([tap]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.cancel();
    await tester.pump(settle);

    expect(sink.of<TapCancel>(), hasLength(1));
    expect(sink.of<TapUp>(), hasLength(1));
    expect(sink.of<TapUp>().single.scene, Vector2.all(5));
    expect(sink.of<TapUp>().single.details.globalPosition, const Offset(5, 5));

    // The tap never happened, so only the release it lost is taken back.
    expect(sink.of<Tap>(), isEmpty);
    expect(tap.isDown, isFalse);
  });

  testWidgets('a contested tap held past the press timeout announces, then cancels', (
    tester,
  ) async {
    final tap = TapInput(
      shape: .square(200),
      priority: 1,
      behavior: .translucent,
    );

    final drag = DragInput(shape: .square(200));
    final sink = TestSink([tap, drag]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await tester.pump(kPressTimeout + settle);
    expect(sink.of<TapDown>(), hasLength(1), reason: 'the deadline elapsed');

    await gesture.moveBy(const Offset(50, 0));
    await gesture.up();
    await tester.pump(settle);

    expect(sink.of<TapCancel>(), hasLength(1));
  });

  testWidgets('a small movement wins as a tap over a contesting drag', (tester) async {
    final tap = TapInput(
      shape: .square(200),
      priority: 1,
      behavior: .translucent,
    );

    final drag = DragInput(shape: .square(200));
    final sink = TestSink([tap, drag]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.up();
    await tester.pump(settle);

    expect(sink.of<TapUp>(), hasLength(1));
    expect(sink.of<DragStart>(), isEmpty);
  });

  testWidgets('a lower-priority sibling of the same kind never fires when overlapped', (
    tester,
  ) async {
    final a = TapInput(shape: .square(200), priority: 1);
    final b = TapInput(shape: .square(200));
    final sink = TestSink([a, b]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.up();
    await tester.pump(settle);

    expect(sink.of<TapUp>().map((event) => event.input), [a]);
  });

  testWidgets('register reports whether the node claimed the down event', (tester) async {
    final tap = TapInput(shape: .square(20));
    final drag = DragInput(shape: .square(20));
    final hover = HoverInput(shape: .square(20));
    await pumpScene(tester, [tap, drag, hover]);

    const down = PointerDownEvent(pointer: 1, position: Offset(5, 5));
    expect(tap.register(down, (offset) => offset), InputResult.handled);
    expect(drag.register(down, (offset) => offset), InputResult.handled);
    expect(hover.register(down, (offset) => offset), InputResult.ignored);

    // Settle the arena the manual registrations above just joined, off both
    // hit areas so real routing doesn't register either node a second time.
    final gesture = await tester.startGesture(const Offset(500, 500), pointer: 1);
    await gesture.up();
    await tester.pump(settle);
  });

  testWidgets('a HoverInput above a DragInput still lets drags through', (tester) async {
    final hover = HoverInput(shape: .square(200), priority: 1);
    final drag = DragInput(shape: .square(200));
    final sink = TestSink([hover, drag]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    await gesture.up();
    await tester.pump(settle);

    expect(sink.of<DragStart>(), hasLength(1));
  });

  testWidgets('a HoverInput below a DragInput still receives hover', (tester) async {
    final drag = DragInput(shape: .square(200), priority: 1);
    final hover = HoverInput(shape: .square(200));
    final sink = TestSink([drag, hover]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(500, 500)); // Starts outside the hit area.
    await tester.pump();

    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();

    expect(sink.of<HoverEnter>(), hasLength(1));
  });

  testWidgets('a HoverInput above a TapInput still lets taps through', (tester) async {
    final hover = HoverInput(shape: .square(200), priority: 1);
    final tap = TapInput(shape: .square(200));
    final sink = TestSink([hover, tap]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.up();
    await tester.pump(settle);

    expect(sink.of<TapUp>(), hasLength(1));
  });

  testWidgets('a HoverInput below a TapInput still receives hover', (tester) async {
    final tap = TapInput(shape: .square(200), priority: 1);
    final hover = HoverInput(shape: .square(200));
    final sink = TestSink([tap, hover]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(500, 500)); // Starts outside the hit area.
    await tester.pump();

    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();

    expect(sink.of<HoverEnter>(), hasLength(1));
  });

  testWidgets('isHovering tracks hover', (tester) async {
    final hover = HoverInput(shape: .square(20));
    await pumpScene(tester, [hover]);

    expect(hover.isHovering, isFalse);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(500, 500)); // Starts outside the hit area.
    await tester.pump();

    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();
    expect(hover.isHovering, isTrue);

    await gesture.moveTo(const Offset(500, 500));
    await tester.pump();
    expect(hover.isHovering, isFalse);
  });

  testWidgets('hover enters as the event arrives, before the next frame', (tester) async {
    final hover = HoverInput(shape: .square(20));
    final sink = TestSink([hover]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(500, 500));
    await tester.pump();

    await gesture.moveTo(const Offset(5, 5));
    expect(sink.of<HoverEnter>(), hasLength(1));
  });

  testWidgets('hover emits enter then exit', (tester) async {
    final hover = HoverInput(shape: .square(20));
    final sink = TestSink([hover]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(500, 500)); // Starts outside the hit area.
    await tester.pump();

    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();
    expect(sink.of<HoverEnter>(), hasLength(1));
    expect(sink.of<HoverExit>(), isEmpty);

    await gesture.moveTo(const Offset(500, 500));
    await tester.pump();
    expect(sink.of<HoverExit>(), hasLength(1));
  });

  testWidgets('unmounting mid-hover emits HoverExit', (tester) async {
    final hover = HoverInput(shape: .square(20));
    var exits = 0;
    final reads = <String>[];

    final parent = TestNode(
      processor: (_, event) {
        if (event is! HoverExit) return;
        exits += 1;
        reads.add(hover.read<String>());
      },
      children: [hover],
    );

    final subtree = Node(children: [parent]);
    final scene = await pumpScene(tester, [subtree]);
    scene.root.provide('cursor');

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(500, 500));
    await tester.pump();

    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();
    expect(hover.isHovering, isTrue);

    scene.root.remove(subtree);
    await tester.pump();

    expect(exits, 1);
    expect(reads, ['cursor']);
    expect(hover.isHovering, isFalse);
  });

  testWidgets('a hover event after the hovered node unmounted emits nothing', (tester) async {
    final hover = HoverInput(shape: .square(20));
    final sink = TestSink([hover]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(500, 500));
    await tester.pump();

    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();

    sink.remove(hover);
    await tester.pump();
    expect(sink.of<HoverExit>(), hasLength(1));

    await gesture.moveTo(const Offset(500, 500));
    await tester.pump();

    expect(sink.of<HoverExit>(), hasLength(1));
  });

  testWidgets('a node that moves under a still cursor is hovered', (tester) async {
    final hover = HoverInput(shape: .square(20), position: .all(100));
    await pumpScene(tester, [hover]);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(500, 500));
    await tester.pump();

    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();
    expect(hover.isHovering, isFalse);

    hover.position.setZero();
    await tester.pump();

    expect(hover.isHovering, isTrue);
  });

  testWidgets('a mouse leaving the scene clears its hover', (tester) async {
    final hover = HoverInput(shape: .square(20));
    await pumpScene(tester, [hover]);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(500, 500));
    await tester.pump();

    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();
    expect(hover.isHovering, isTrue);

    await gesture.removePointer();
    await tester.pump();

    expect(hover.isHovering, isFalse);
  });

  testWidgets('unmounting mid-drag cancels the drag', (tester) async {
    final drag = DragInput(shape: .square(200));
    final sink = TestSink([drag]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    await tester.pump(settle);
    expect(drag.isDragging, isTrue);

    sink.remove(drag);
    await tester.pump();

    expect(sink.of<DragCancel>(), hasLength(1));
    expect(sink.of<DragEnd>(), isEmpty);
    expect(drag.isDragging, isFalse);

    // The arena resolution the release would have triggered is already spent,
    // so it must not emit a second terminal event.
    await gesture.up();
    await tester.pump(settle);

    expect(sink.of<DragCancel>(), hasLength(1));
  });

  testWidgets('unmounting mid-drag honors endOnCancel', (tester) async {
    final drag = DragInput(shape: .square(200), endOnCancel: true);
    final sink = TestSink([drag]);
    await pumpScene(tester, [sink]);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    await tester.pump(settle);

    sink.remove(drag);
    await tester.pump();
    await gesture.up();
    await tester.pump(settle);

    expect(sink.of<DragCancel>(), hasLength(1));
    expect(sink.of<DragEnd>(), hasLength(1));
    expect(sink.of<DragEnd>().single.details.globalPosition, const Offset(55, 5));
  });
}
