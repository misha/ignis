import 'package:flutter/gestures.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';
import 'package:ignis/src/input_router.dart';

void main() {
  Scene<Node> makeInputScene(InputNode input) {
    final scene = Node(children: [input]).mount();
    scene.resize(100, 80);
    return scene;
  }

  test('down hits the topmost InputNode and emits onPointerDown', () {
    final input = InputNode(shape: .rectangle, size: .all(10), position: .zero());
    final router = InputRouter(makeInputScene(input));
    final downs = <PointerInfo>[];
    input.onPointerDown(downs.add);

    router.handle(const PointerDownEvent(pointer: 1, position: Offset(5, 5)));

    expect(downs, hasLength(1));
    expect(downs.single.id, 1);
    expect(downs.single.scene, Vector2.all(5));
  });

  test('a down that misses every InputNode emits nothing', () {
    final input = InputNode(shape: .rectangle, size: .all(10), position: .zero());
    final router = InputRouter(makeInputScene(input));
    final downs = <PointerInfo>[];
    input.onPointerDown(downs.add);

    router.handle(const PointerDownEvent(pointer: 1, position: Offset(50, 50)));

    expect(downs, isEmpty);
  });

  test('capture keeps routing move and up to the same node once it leaves the hit area', () {
    final input = InputNode(shape: .rectangle, size: .all(10), position: .zero());
    final router = InputRouter(makeInputScene(input));
    final moves = <PointerInfo>[];
    final ups = <PointerInfo>[];
    input.onPointerMove(moves.add);
    input.onPointerUp(ups.add);

    router.handle(const PointerDownEvent(pointer: 1, position: Offset(5, 5)));
    router.handle(const PointerMoveEvent(pointer: 1, position: Offset(90, 70)));
    router.handle(const PointerUpEvent(pointer: 1, position: Offset(90, 70)));

    expect(moves, hasLength(1));
    expect(ups, hasLength(1));
    expect(ups.single.scene, Vector2(90, 70));
  });

  test('a move for a pointer that never captured anything is ignored', () {
    final input = InputNode(shape: .rectangle, size: .all(10), position: .zero());
    final router = InputRouter(makeInputScene(input));
    final moves = <PointerInfo>[];
    input.onPointerMove(moves.add);

    router.handle(const PointerDownEvent(pointer: 1, position: Offset(50, 50)));
    router.handle(const PointerMoveEvent(pointer: 1, position: Offset(5, 5)));

    expect(moves, isEmpty);
  });

  test('cancel clears capture and emits onPointerCancel instead of onPointerUp', () {
    final input = InputNode(shape: .rectangle, size: .all(10), position: .zero());
    final router = InputRouter(makeInputScene(input));
    final ups = <PointerInfo>[];
    final cancels = <PointerInfo>[];
    input.onPointerUp(ups.add);
    input.onPointerCancel(cancels.add);

    router.handle(const PointerDownEvent(pointer: 1, position: Offset(5, 5)));
    router.handle(const PointerCancelEvent(pointer: 1, position: Offset(5, 5)));
    router.handle(const PointerUpEvent(pointer: 1, position: Offset(5, 5)));

    expect(cancels, hasLength(1));
    expect(ups, isEmpty); // The pointer was already released by the cancel.
  });

  test('hover emits onPointerEnter then onPointerExit as the pointer crosses the hit area', () {
    final input = InputNode(shape: .rectangle, size: .all(10), position: .zero());
    final router = InputRouter(makeInputScene(input));
    final enters = <PointerInfo>[];
    final exits = <PointerInfo>[];
    input.onPointerEnter(enters.add);
    input.onPointerExit(exits.add);

    router.handle(const PointerHoverEvent(pointer: 1, position: Offset(5, 5)));
    expect(enters, hasLength(1));
    expect(exits, isEmpty);

    router.handle(const PointerHoverEvent(pointer: 1, position: Offset(5, 5)));
    expect(enters, hasLength(1)); // Still inside.

    router.handle(const PointerHoverEvent(pointer: 1, position: Offset(50, 50)));
    expect(exits, hasLength(1));
  });
}
