import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

enum _Game { pause }

/// A game's own node, answering an action from inside the scene.
final class _Mine extends Node {
  final Object action;
  final void Function() onFire;

  _Mine(this.action, this.onFire);

  @override
  void build() {
    super.build();
    Ignis.controls.claim(action, (_) => onFire());
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Scene<Node> scene;

  setUp(() {
    Ignis.controls = Controls();
    Ignis.debug = Debug();
    scene = Node().mount();
  });

  /// Puts [node] in the scene under test and builds it.
  void add(Node node) {
    scene.node.add(node);
    scene.update(0);
  }

  tearDown(() => scene.destroy());

  bool press(LogicalKeyboardKey key, {bool shift = false}) {
    return Ignis.controls.dispatch(KeyPress(key, shift: shift));
  }

  test('one call installs the lot on their default keys', () {
    add(DebugControlsNode());

    expect(press(.f2), isTrue);
    expect(press(.f2, shift: true), isTrue);
    expect(press(.f3), isTrue);
    expect(press(.f1), isTrue);
  });

  test('pause freezes the scene the node is in, and no other', () {
    add(DebugControlsNode());
    final other = Node().mount();

    press(.f1);
    expect(scene.paused, isTrue);
    expect(other.paused, isFalse, reason: 'a node speaks for its own scene');

    press(.f1);
    expect(scene.paused, isFalse);
    other.destroy();
  });

  test('a paused scene still reaches the node that resumes it', () {
    add(DebugControlsNode());

    press(.f1);
    expect(scene.paused, isTrue);

    expect(press(.f1), isTrue, reason: 'dispatch never reads paused');
    expect(scene.paused, isFalse);
  });

  test('a null key leaves that one unbound and the rest alone', () {
    add(DebugControlsNode(off: null));

    expect(press(.f3), isFalse);
    expect(press(.f2), isTrue);
  });

  test('a declined default still answers a key the game binds itself', () {
    add(DebugControlsNode(off: null));
    Ignis.controls.bind(DebugAction.off, {const KeyPress(.f4)});

    press(.f2);
    expect(Ignis.debug.enabled, isTrue);

    expect(press(.f4), isTrue);
    expect(Ignis.debug.enabled, isFalse, reason: 'the claim was there waiting');
  });

  test('a key can be remapped without touching the others', () {
    add(DebugControlsNode(pause: const KeyPress(.escape)));

    expect(press(.f1), isFalse);
    expect(press(.escape), isTrue);
    expect(scene.paused, isTrue);
  });

  test('a game node outranks the debug node on the same action', () {
    var mine = 0;
    add(DebugControlsNode());
    add(_Mine(DebugAction.pause, () => mine += 1));

    press(.f1);

    expect(mine, 1);
    expect(scene.paused, isFalse, reason: 'debug sits at -1000, so it never ran');
  });

  test('a game can bind its own action to a key debug already uses', () {
    var mine = 0;
    add(DebugControlsNode());
    Ignis.controls.bind(_Game.pause, {const KeyPress(.f1)});
    add(_Mine(_Game.pause, () => mine += 1));

    press(.f1);

    expect(mine, 1, reason: 'both actions are bound to F1');
    expect(scene.paused, isTrue, reason: 'and both ran, being different actions');
  });

  test('detaching the node removes every binding and claim', () {
    final node = DebugControlsNode();
    add(node);

    node.detach();
    scene.update(0);

    expect(press(.f1), isFalse);
    expect(press(.f2), isFalse);
    expect(Ignis.controls.bindings, isEmpty, reason: 'the build owned the lot');
  });

  group('the cycle', () {
    test('opens on every wireframe at once', () {
      expect(Ignis.debug.enabled, isFalse);
      add(DebugControlsNode());

      press(.f2);

      expect(Ignis.debug.mode, DebugMode.all);
    });

    test('then takes them one at a time, in order', () {
      add(DebugControlsNode());

      press(.f2);
      press(.f2);
      expect(Ignis.debug.mode, DebugMode.transforms);
      expect(Ignis.debug.draws(.collisions), isFalse, reason: 'only that one now');

      press(.f2);
      expect(Ignis.debug.mode, DebugMode.collisions);

      press(.f2);
      expect(Ignis.debug.mode, DebugMode.inputs);

      press(.f2);
      expect(Ignis.debug.mode, DebugMode.layouts);
    });

    test('wraps from the last mode straight back to the first', () {
      add(DebugControlsNode());

      for (var i = 0; i < DebugMode.values.length; i += 1) {
        press(.f2);
      }

      expect(Ignis.debug.mode, DebugMode.layouts, reason: 'the last mode');

      press(.f2);

      expect(Ignis.debug.mode, DebugMode.all, reason: 'round to the first again');
    });

    test('never passes through off, however far it goes round', () {
      add(DebugControlsNode());

      for (var i = 0; i < DebugMode.values.length * 3; i += 1) {
        press(.f2);
        expect(Ignis.debug.enabled, isTrue, reason: 'off is not a step in the round');
      }
    });

    test('shift steps it backwards', () {
      add(DebugControlsNode());

      press(.f2);
      press(.f2);
      press(.f2);
      expect(Ignis.debug.mode, DebugMode.collisions);

      press(.f2, shift: true);
      expect(Ignis.debug.mode, DebugMode.transforms);

      press(.f2, shift: true);
      expect(Ignis.debug.mode, DebugMode.all);
    });

    test('shift wraps backwards past the first, skipping off', () {
      add(DebugControlsNode());

      press(.f2);
      expect(Ignis.debug.mode, DebugMode.all);

      press(.f2, shift: true);

      expect(Ignis.debug.mode, DebugMode.layouts, reason: 'round to the last, not off');
    });

    test('shift from off opens on the last mode', () {
      add(DebugControlsNode());

      press(.f2, shift: true);

      expect(Ignis.debug.mode, DebugMode.layouts);
    });
  });

  group('off', () {
    test('is one press out from wherever the cycle stopped', () {
      add(DebugControlsNode());

      press(.f2);
      press(.f2);
      press(.f3);

      expect(Ignis.debug.mode, isNull);
      expect(Ignis.debug.enabled, isFalse);
    });

    test('leaves the next press opening on the first mode again', () {
      add(DebugControlsNode());

      press(.f2);
      press(.f2);
      press(.f2);
      press(.f3);
      press(.f2);

      expect(Ignis.debug.mode, DebugMode.all, reason: 'F3 then F2 is a reset');
    });

    test('on an overlay already off does nothing', () {
      add(DebugControlsNode());

      expect(press(.f3), isTrue, reason: 'the action still ran');
      expect(Ignis.debug.mode, isNull);
    });

    test('stops every wireframe drawing', () {
      add(DebugControlsNode());

      press(.f2);
      expect(Ignis.debug.draws(.transforms), isTrue);

      press(.f3);

      for (final wireframe in DebugMode.values) {
        expect(Ignis.debug.draws(wireframe), isFalse, reason: '$wireframe is off with it');
      }
    });
  });
}
