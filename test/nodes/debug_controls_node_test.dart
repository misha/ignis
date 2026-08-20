import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

/// A game's own node, answering a key from inside the scene.
final class _Mine extends Node {
  final ControlEvent matcher;
  final void Function() onFire;

  _Mine(this.matcher, this.onFire);

  @override
  void build() {
    super.build();
    Ignis.controls.bind((_) => onFire(), matchers: {matcher});
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

    expect(press(.f1), isTrue);
    expect(press(.f2), isTrue);
    expect(press(.f3), isTrue);
    expect(press(.f4), isTrue);
    expect(press(.f5), isTrue);
    expect(press(.f6), isTrue);
  });

  test('pause freezes the scene the node is in, and no other', () {
    add(DebugControlsNode());
    final other = Node().mount();

    press(.f5);
    expect(scene.paused, isTrue);
    expect(other.paused, isFalse, reason: 'a node speaks for its own scene');

    press(.f5);
    expect(scene.paused, isFalse);
    other.destroy();
  });

  test('a paused scene still reaches the node that resumes it', () {
    add(DebugControlsNode());

    press(.f5);
    expect(scene.paused, isTrue);

    expect(press(.f5), isTrue, reason: 'dispatch never reads paused');
    expect(scene.paused, isFalse);
  });

  test('a declined control leaves that one unbound and the rest alone', () {
    add(DebugControlsNode(inputs: const {}));

    expect(press(.f3), isFalse);
    expect(press(.f2), isTrue);
  });

  test('a remapped control takes the key the game gives it', () {
    add(DebugControlsNode(collisions: {const KeyPress(.f9)}));

    expect(press(.f2), isFalse, reason: 'the default went with the remap');

    press(.f9);

    expect(Ignis.debug.draws(.collisions), isTrue);
  });

  test('a key can be remapped without touching the others', () {
    add(DebugControlsNode(pause: {const KeyPress(.escape)}));

    expect(press(.f5), isFalse);
    expect(press(.escape), isTrue);
    expect(scene.paused, isTrue);
  });

  test('a game node outranks the debug node on the same key', () {
    var mine = 0;
    add(DebugControlsNode());
    add(_Mine(const KeyPress(.f5), () => mine += 1));

    press(.f5);

    expect(mine, 1);
    expect(scene.paused, isFalse, reason: 'debug sits at -1000, so it never ran');
  });

  test('a group switches every debug control off together', () {
    add(DebugControlsNode(groups: const {'debug'}));

    press(.f2);
    expect(Ignis.debug.enabled, isTrue);

    Ignis.controls.disable('debug');

    expect(press(.f2), isFalse);
    expect(press(.f5), isFalse);
    expect(scene.paused, isFalse);
  });

  test('detaching the node removes every control it bound', () {
    final node = DebugControlsNode();
    add(node);

    node.detach();
    scene.update(0);

    expect(press(.f1), isFalse);
    expect(press(.f2), isFalse);
    expect(press(.f3), isFalse);
    expect(press(.f4), isFalse);
    expect(press(.f5), isFalse);
    expect(press(.f6), isFalse, reason: 'the build owned the lot');
  });

  group('the wireframes', () {
    test('each key draws its own, and no other', () {
      add(DebugControlsNode());

      press(.f2);

      expect(Ignis.debug.mode, DebugMode.collisions);
    });

    test('they combine, so any set of them draws at once', () {
      add(DebugControlsNode());

      press(.f1);
      press(.f4);

      expect(Ignis.debug.draws(.transforms), isTrue);
      expect(Ignis.debug.draws(.layouts), isTrue);
      expect(Ignis.debug.draws(.collisions), isFalse);
      expect(Ignis.debug.draws(.inputs), isFalse);
    });

    test('a second press takes one back out, and leaves the rest', () {
      add(DebugControlsNode());

      press(.f1);
      press(.f2);
      press(.f1);

      expect(Ignis.debug.draws(.transforms), isFalse);
      expect(Ignis.debug.draws(.collisions), isTrue);
    });

    test('the last one out leaves the overlay off', () {
      add(DebugControlsNode());

      press(.f3);
      expect(Ignis.debug.enabled, isTrue);

      press(.f3);

      expect(Ignis.debug.mode, DebugMode.none);
      expect(Ignis.debug.enabled, isFalse);
    });

    test('one key fills the overlay, and the next empties it', () {
      add(DebugControlsNode());

      press(.f6);
      expect(Ignis.debug.mode, DebugMode.all);

      press(.f6);
      expect(Ignis.debug.mode, DebugMode.none);
    });

    test('it fills from part of the way in, rather than emptying', () {
      add(DebugControlsNode());

      press(.f2);
      press(.f6);

      expect(Ignis.debug.mode, DebugMode.all, reason: 'short of full fills it');
    });

    test('every one of them at once is every wireframe there is', () {
      add(DebugControlsNode());

      press(.f1);
      press(.f2);
      press(.f3);
      press(.f4);

      expect(Ignis.debug.mode, DebugMode.all);

      for (final wireframe in DebugMode.values) {
        expect(Ignis.debug.draws(wireframe), isTrue, reason: '$wireframe draws with the rest');
      }
    });
  });
}
