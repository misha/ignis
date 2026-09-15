import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_device.dart';

void main() {
  group('KeyPress', () {
    group('accepts', () {
      test('the same key with nothing required', () {
        expect(KeyPress(.space).accepts(KeyPress(.space)), isTrue);
      });

      test('only that key', () {
        expect(KeyPress(.space).accepts(KeyPress(.enter)), isFalse);
      });

      test('a required modifier must be held', () {
        const bound = KeyPress(.keyS, control: true);

        expect(bound.accepts(KeyPress(.keyS)), isFalse);
        expect(bound.accepts(KeyPress(.keyS, control: true)), isTrue);
      });

      test('every required modifier must be held', () {
        const bound = KeyPress(.keyS, control: true, shift: true);

        expect(bound.accepts(KeyPress(.keyS, control: true)), isFalse);
        expect(bound.accepts(KeyPress(.keyS, control: true, shift: true)), isTrue);
      });

      test('a modifier left null takes the press either way', () {
        expect(KeyPress(.space).accepts(KeyPress(.space, shift: true)), isTrue);
        expect(KeyPress(.space).accepts(KeyPress(.space, shift: false)), isTrue);

        expect(
          KeyPress(.keyS, control: true) //
              .accepts(KeyPress(.keyS, control: true, shift: true)),
          isTrue,
          reason: 'an unmatched modifier does not block a match',
        );
      });

      test('a modifier required released takes a press that never mentions it', () {
        const bound = KeyPress(.f2, shift: false);

        expect(
          bound.accepts(KeyPress(.f2)),
          isTrue,
          reason: 'null emitted reads as released',
        );
      });

      test('released and held split one key between two bindings', () {
        const forward = KeyPress(.f2, shift: false);
        const back = KeyPress(.f2, shift: true);

        expect(forward.accepts(KeyPress(.f2, shift: false)), isTrue);
        expect(forward.accepts(KeyPress(.f2, shift: true)), isFalse);
        expect(back.accepts(KeyPress(.f2, shift: true)), isTrue);
        expect(back.accepts(KeyPress(.f2, shift: false)), isFalse);
      });

      test('one modifier released says nothing about the others', () {
        const bound = KeyPress(.f2, shift: false);

        expect(bound.accepts(KeyPress(.f2, control: true)), isTrue);
      });

      test('an event of another kind never matches', () {
        expect(KeyPress(.space).accepts(const TestEvent()), isFalse);
      });
    });

    group('value', () {
      test('equal keys and modifiers are equal', () {
        expect(
          KeyPress(.keyS, control: true),
          KeyPress(.keyS, control: true),
        );

        expect(
          KeyPress(.keyS, control: true).hashCode,
          KeyPress(.keyS, control: true).hashCode,
        );
      });

      test('a required modifier tells it apart', () {
        expect(KeyPress(.keyS), isNot(KeyPress(.keyS, control: true)));
      });

      test('asking for a modifier released differs from not asking', () {
        expect(KeyPress(.keyS, control: false), isNot(KeyPress(.keyS)));
      });

      test('reads as the chord it stands for', () {
        expect(
          KeyPress(.keyS, control: true, shift: true).toString(),
          'ctrl+shift+Key S',
        );
      });

      test('a bare key reads as itself', () {
        expect(KeyPress(.space).toString(), LogicalKeyboardKey.space.debugName);
      });
    });
  });

  group('KeyboardDevice', () {
    late KeyboardDevice keyboard;
    late List<ControlEvent> fired;

    setUp(() {
      fired = [];
      keyboard = KeyboardDevice();

      Ignis.controls = Controls()
        ..install(keyboard)
        ..bind(fired.add, matchers: {KeyPress(.keyF)});
    });

    Future<void> pump(WidgetTester tester, {bool mounted = true}) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child:
              mounted //
              ? SceneWidget(Node().mount(), autofocus: false)
              : const SizedBox.shrink(),
        ),
      );
    }

    testWidgets('a key down reaches the claim', (tester) async {
      await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);

      expect(fired, hasLength(1));
      expect((fired.single as KeyPress).key, LogicalKeyboardKey.keyF);
    });

    testWidgets('modifiers travel with the press', (tester) async {
      await pump(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.controlLeft);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);
      await tester.sendKeyUpEvent(LogicalKeyboardKey.controlLeft);

      expect((fired.single as KeyPress).control, isTrue);
    });

    testWidgets('a key up runs nothing', (tester) async {
      await pump(tester);
      await tester.sendKeyDownEvent(LogicalKeyboardKey.keyF);
      fired.clear();
      await tester.sendKeyUpEvent(LogicalKeyboardKey.keyF);

      expect(fired, isEmpty);
    });

    testWidgets('uninstalling stops the keyboard reaching it', (tester) async {
      await pump(tester);
      Ignis.controls.uninstall(keyboard);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);

      expect(fired, isEmpty);
    });

    testWidgets('controls with no device hear nothing', (tester) async {
      Ignis.controls = Controls()..bind(fired.add, matchers: {KeyPress(.keyF)});

      await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);

      expect(fired, isEmpty, reason: 'listening is opt-in');
    });

    testWidgets('installing one keyboard twice still runs a handler once', (tester) async {
      Ignis.controls
        ..install(keyboard)
        ..install(keyboard);

      await pump(tester);
      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);

      expect(fired, hasLength(1));
    });

    testWidgets('two scenes on one page still run an action once', (tester) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: Column(
            children: [
              Expanded(child: SceneWidget(Node().mount(), autofocus: false)),
              Expanded(child: SceneWidget(Node().mount(), autofocus: false)),
            ],
          ),
        ),
      );

      await tester.sendKeyEvent(LogicalKeyboardKey.keyF);

      expect(fired, hasLength(1), reason: 'one keyboard, one handler');
    });
  });
}
