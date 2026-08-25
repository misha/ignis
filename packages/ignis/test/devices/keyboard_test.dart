import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

/// Stands in for a gamepad or a plugin's event.
final class _Other implements ControlEvent {
  const _Other();

  @override
  bool accepts(ControlEvent emitted) => emitted is _Other;
}

void main() {
  group('KeyPress', () {
    group('accepts', () {
      test('the same key with nothing required', () {
        expect(const KeyPress(.space).accepts(const KeyPress(.space)), isTrue);
      });

      test('only that key', () {
        expect(const KeyPress(.space).accepts(const KeyPress(.enter)), isFalse);
      });

      test('a required modifier must be held', () {
        const bound = KeyPress(.keyS, control: true);

        expect(bound.accepts(const KeyPress(.keyS)), isFalse);
        expect(bound.accepts(const KeyPress(.keyS, control: true)), isTrue);
      });

      test('every required modifier must be held', () {
        const bound = KeyPress(.keyS, control: true, shift: true);

        expect(bound.accepts(const KeyPress(.keyS, control: true)), isFalse);
        expect(bound.accepts(const KeyPress(.keyS, control: true, shift: true)), isTrue);
      });

      test('a modifier left null takes the press either way', () {
        expect(const KeyPress(.space).accepts(const KeyPress(.space, shift: true)), isTrue);
        expect(const KeyPress(.space).accepts(const KeyPress(.space, shift: false)), isTrue);

        expect(
          const KeyPress(.keyS, control: true).accepts(
            const KeyPress(.keyS, control: true, shift: true),
          ),
          isTrue,
          reason: 'an extra modifier nobody asked about never blocks a match',
        );
      });

      test('a modifier required released takes a press that never mentions it', () {
        const bound = KeyPress(.f2, shift: false);

        expect(
          bound.accepts(const KeyPress(.f2)),
          isTrue,
          reason: 'null emitted reads as released',
        );
      });

      test('released and held split one key between two bindings', () {
        const forward = KeyPress(.f2, shift: false);
        const back = KeyPress(.f2, shift: true);

        expect(forward.accepts(const KeyPress(.f2, shift: false)), isTrue);
        expect(forward.accepts(const KeyPress(.f2, shift: true)), isFalse);
        expect(back.accepts(const KeyPress(.f2, shift: true)), isTrue);
        expect(back.accepts(const KeyPress(.f2, shift: false)), isFalse);
      });

      test('one modifier released says nothing about the others', () {
        const bound = KeyPress(.f2, shift: false);

        expect(bound.accepts(const KeyPress(.f2, control: true)), isTrue);
      });

      test('an event of another kind never matches', () {
        expect(const KeyPress(.space).accepts(const _Other()), isFalse);
      });
    });

    group('value', () {
      test('equal keys and modifiers are equal', () {
        expect(const KeyPress(.keyS, control: true), const KeyPress(.keyS, control: true));
        expect(
          const KeyPress(.keyS, control: true).hashCode,
          const KeyPress(.keyS, control: true).hashCode,
        );
      });

      test('a required modifier tells it apart', () {
        expect(const KeyPress(.keyS), isNot(const KeyPress(.keyS, control: true)));
      });

      test('asking for a modifier released differs from not asking', () {
        expect(const KeyPress(.keyS, control: false), isNot(const KeyPress(.keyS)));
      });

      test('reads as the chord it stands for', () {
        expect(
          const KeyPress(.keyS, control: true, shift: true).toString(),
          'ctrl+shift+Key S',
        );
      });

      test('a bare key reads as itself', () {
        expect(const KeyPress(.space).toString(), LogicalKeyboardKey.space.debugName);
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
        ..bind(fired.add, matchers: {const KeyPress(.keyF)});
    });

    Future<void> pump(WidgetTester tester, {bool mounted = true}) async {
      await tester.pumpWidget(
        Directionality(
          textDirection: .ltr,
          child: mounted ? SceneWidget(Node().mount(), autofocus: false) : const SizedBox.shrink(),
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
      Ignis.controls = Controls()..bind(fired.add, matchers: {const KeyPress(.keyF)});

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
