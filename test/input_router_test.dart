import 'package:flutter/gestures.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';
import 'package:ignis/src/scene_render_box.dart';

void main() {
  Future<Scene<Node>> pumpScene(WidgetTester tester, Iterable<Node> children) async {
    final scene = Node(children: children).mount();
    scene.resize(800, 600);
    await tester.pumpWidget(RenderSceneWidget(scene: scene, addRepaintBoundary: true));
    return scene;
  }

  // MultiTapGestureRecognizer has an internal kDoubleTapMinTime timer.
  const settle = Duration(milliseconds: 50);

  testWidgets('a hit fires onTapDown', (tester) async {
    final tap = TapInput(shape: .square(20));
    await pumpScene(tester, [tap]);
    final downs = <TapDownEvent>[];
    tap.onTapDown(downs.add);

    await tester.startGesture(const Offset(5, 5));
    await tester.pump(settle);

    expect(downs, hasLength(1));
    expect(downs.single.scene, Vector2.all(5));
  });

  testWidgets('a miss fires nothing', (tester) async {
    final tap = TapInput(shape: .square(20));
    await pumpScene(tester, [tap]);
    final downs = <TapDownEvent>[];
    tap.onTapDown(downs.add);

    await tester.startGesture(const Offset(500, 500));
    await tester.pump(settle);

    expect(downs, isEmpty);
  });

  testWidgets('a clean release fires onTapUp and onTap', (tester) async {
    final tap = TapInput(shape: .square(20));
    await pumpScene(tester, [tap]);
    final ups = <TapUpEvent>[];
    var taps = 0;
    tap.onTapUp(ups.add);
    tap.onTap(() => taps += 1);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.up();
    await tester.pump(settle);

    expect(ups, hasLength(1));
    expect(taps, 1);
  });

  testWidgets('moving past the slop cancels instead of firing onTapUp', (tester) async {
    final tap = TapInput(shape: .square(200));
    await pumpScene(tester, [tap]);
    final ups = <TapUpEvent>[];
    var cancels = 0;
    tap.onTapUp(ups.add);
    tap.onTapCancel(() => cancels += 1);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    await gesture.up();
    await tester.pump(settle);

    expect(cancels, 1);
    expect(ups, isEmpty);
  });

  testWidgets('dragging past the slop starts, then updates with the right delta', (tester) async {
    final drag = DragInput(shape: .square(200));
    await pumpScene(tester, [drag]);
    final starts = <DragStartEvent>[];
    final updates = <DragUpdateEvent>[];
    drag.onDragStart(starts.add);
    drag.onDragUpdate(updates.add);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    await gesture.up();
    await tester.pump(settle);

    expect(starts, hasLength(1));
    expect(starts.single.scene, Vector2.all(5));
    expect(updates, isNotEmpty);
    // Flutter reports the down position as the first update's globalPosition,
    // so its delta must come out zero.
    expect(updates.first.delta, Vector2.zero());
    expect(updates.last.scene, Vector2(55, 5));
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

  testWidgets('a cancelled drag does not emit onDragEnd by default', (tester) async {
    final drag = DragInput(shape: .square(200));
    await pumpScene(tester, [drag]);
    final ends = <DragEndEvent>[];
    var cancels = 0;
    drag.onDragEnd(ends.add);
    drag.onDragCancel(() => cancels += 1);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    await gesture.cancel();
    await tester.pump(settle);

    expect(cancels, 1);
    expect(ends, isEmpty);
  });

  testWidgets('endOnCancel manufactures onDragEnd from the last known position', (tester) async {
    final drag = DragInput(shape: .square(200), endOnCancel: true);
    await pumpScene(tester, [drag]);
    final ends = <DragEndEvent>[];
    var cancels = 0;
    drag.onDragEnd(ends.add);
    drag.onDragCancel(() => cancels += 1);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    await gesture.cancel();
    await tester.pump(settle);

    expect(cancels, 1);
    expect(ends, hasLength(1));
    expect(ends.single.details.globalPosition, const Offset(55, 5));
  });

  testWidgets('delta stays correct under a scaling ancestor', (tester) async {
    final drag = DragInput(shape: .square(200));
    final scene = Node(children: [drag]).mount();
    scene.resize(800, 600);

    await tester.pumpWidget(
      Transform.scale(
        scale: 2,
        alignment: .topLeft,
        child: RenderSceneWidget(scene: scene, addRepaintBoundary: true),
      ),
    );

    final updates = <DragUpdateEvent>[];
    drag.onDragUpdate(updates.add);

    final gesture = await tester.startGesture(const Offset(10, 10));
    await gesture.moveBy(const Offset(100, 0));
    await gesture.up();
    await tester.pump(settle);

    // 100 units of window movement is 50 units of scene movement at 2x scale.
    expect(updates.last.delta.x, closeTo(50, 0.001));
  });

  testWidgets('an uncontested drag starts on any movement', (tester) async {
    final drag = DragInput(shape: .square(200));
    await pumpScene(tester, [drag]);
    final starts = <DragStartEvent>[];
    drag.onDragStart(starts.add);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(1, 0));
    await gesture.up();
    await tester.pump(settle);

    // With nothing else contesting this pointer's arena, Flutter's gesture
    // arena resolves the lone recognizer immediately rather than waiting.
    expect(starts, hasLength(1));
  });

  testWidgets('a real drag wins over a contesting tap for the same pointer', (tester) async {
    final tap = TapInput(
      shape: .square(200),
      priority: 1,
      behavior: .translucent,
    );

    final drag = DragInput(shape: .square(200));
    await pumpScene(tester, [tap, drag]);
    final taps = <TapUpEvent>[];
    var cancels = 0;
    final starts = <DragStartEvent>[];
    tap.onTapUp(taps.add);
    tap.onTapCancel(() => cancels += 1);
    drag.onDragStart(starts.add);

    // tap is translucent, so both nodes are offered the down event and their
    // recognizers genuinely contest the same pointer's arena.
    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    await gesture.up();
    await tester.pump(settle);

    expect(starts, hasLength(1));
    expect(cancels, 1);
    expect(taps, isEmpty);
  });

  testWidgets('a small movement wins as a tap over a contesting drag', (tester) async {
    final tap = TapInput(
      shape: .square(200),
      priority: 1,
      behavior: .translucent,
    );

    final drag = DragInput(shape: .square(200));
    await pumpScene(tester, [tap, drag]);
    final taps = <TapUpEvent>[];
    final starts = <DragStartEvent>[];
    tap.onTapUp(taps.add);
    drag.onDragStart(starts.add);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.up();
    await tester.pump(settle);

    expect(taps, hasLength(1));
    expect(starts, isEmpty);
  });

  testWidgets('a lower-priority sibling of the same kind never fires when overlapped', (
    tester,
  ) async {
    final a = TapInput(shape: .square(200), priority: 1);
    final b = TapInput(shape: .square(200));
    await pumpScene(tester, [a, b]);
    final aTaps = <TapUpEvent>[];
    final bTaps = <TapUpEvent>[];
    a.onTapUp(aTaps.add);
    b.onTapUp(bTaps.add);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.up();
    await tester.pump(settle);

    expect(aTaps, hasLength(1));
    expect(bTaps, isEmpty);
  });

  testWidgets('register reports whether the node claimed the down event', (tester) async {
    final tap = TapInput(shape: .square(20));
    final drag = DragInput(shape: .square(20));
    final hover = HoverInput(shape: .square(20));
    await pumpScene(tester, [tap, drag, hover]);

    const down = PointerDownEvent(pointer: 1, position: Offset(5, 5));
    expect(tap.register(down, identity), InputResult.handled);
    expect(drag.register(down, identity), InputResult.handled);
    expect(hover.register(down, identity), InputResult.ignored);

    // Settle the arena the manual registrations above just joined, off both
    // hit areas so real routing doesn't register either node a second time.
    final gesture = await tester.startGesture(const Offset(500, 500), pointer: 1);
    await gesture.up();
    await tester.pump(settle);
  });

  testWidgets('a HoverInput above a DragInput still lets drags through', (tester) async {
    final hover = HoverInput(shape: .square(200), priority: 1);
    final drag = DragInput(shape: .square(200));
    await pumpScene(tester, [hover, drag]);
    final starts = <DragStartEvent>[];
    drag.onDragStart(starts.add);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.moveBy(const Offset(50, 0));
    await gesture.up();
    await tester.pump(settle);

    expect(starts, hasLength(1));
  });

  testWidgets('a HoverInput below a DragInput still receives hover', (tester) async {
    final drag = DragInput(shape: .square(200), priority: 1);
    final hover = HoverInput(shape: .square(200));
    await pumpScene(tester, [drag, hover]);
    final enters = <HoverEvent>[];
    hover.onHoverEnter(enters.add);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(500, 500)); // Starts outside the hit area.
    await tester.pump();

    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();

    expect(enters, hasLength(1));
  });

  testWidgets('a HoverInput above a TapInput still lets taps through', (tester) async {
    final hover = HoverInput(shape: .square(200), priority: 1);
    final tap = TapInput(shape: .square(200));
    await pumpScene(tester, [hover, tap]);
    final taps = <TapUpEvent>[];
    tap.onTapUp(taps.add);

    final gesture = await tester.startGesture(const Offset(5, 5));
    await gesture.up();
    await tester.pump(settle);

    expect(taps, hasLength(1));
  });

  testWidgets('a HoverInput below a TapInput still receives hover', (tester) async {
    final tap = TapInput(shape: .square(200), priority: 1);
    final hover = HoverInput(shape: .square(200));
    await pumpScene(tester, [tap, hover]);
    final enters = <HoverEvent>[];
    hover.onHoverEnter(enters.add);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(500, 500)); // Starts outside the hit area.
    await tester.pump();

    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();

    expect(enters, hasLength(1));
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

  testWidgets('still recognizes taps after being removed and re-added to the tree', (tester) async {
    final root = Node();
    final scene = root.mount();
    scene.resize(800, 600);
    await tester.pumpWidget(RenderSceneWidget(scene: scene, addRepaintBoundary: true));

    final tap = TapInput(shape: .square(20));
    final downs = <TapDownEvent>[];
    tap.onTapDown(downs.add);

    root.add(tap);
    await tester.pump();
    root.remove(tap);
    await tester.pump();
    root.add(tap);
    await tester.pump();

    await tester.startGesture(const Offset(5, 5));
    await tester.pump(settle);

    expect(downs, hasLength(1));
  });

  testWidgets('hover emits enter then exit', (tester) async {
    final hover = HoverInput(shape: .square(20));
    await pumpScene(tester, [hover]);
    final enters = <HoverEvent>[];
    final exits = <HoverEvent>[];
    hover.onHoverEnter(enters.add);
    hover.onHoverExit(exits.add);

    final gesture = await tester.createGesture(kind: PointerDeviceKind.mouse);
    await gesture.addPointer(location: const Offset(500, 500)); // Starts outside the hit area.
    await tester.pump();

    await gesture.moveTo(const Offset(5, 5));
    await tester.pump();
    expect(enters, hasLength(1));
    expect(exits, isEmpty);

    await gesture.moveTo(const Offset(500, 500));
    await tester.pump();
    expect(exits, hasLength(1));
  });
}
