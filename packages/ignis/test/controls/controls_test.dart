import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_device.dart';
import '../support/test_node.dart';

/// A node logging each control it answers as its action and event.
final class _Actor extends Node {
  final List<String> log;

  _Actor(this.log, {super.children});

  @override
  void process(Message message) {
    super.process(message);
    if (message is! Control) return;
    log.add('${message.action}:${message.trigger}');
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Controls controls;
  late List<String> log;
  late _Actor node;
  late _Actor above;
  late Scene scene;

  setUp(() {
    controls = Controls();
    log = [];
    above = _Actor(log);
    node = _Actor(log, children: [above]);
    scene = node.mount();
  });

  tearDown(() => scene.destroy());

  group('binding', () {
    test('reaches its node, with the event that got there', () {
      controls.bind(node, 'jump', matchers: {const NamedTrigger('space')});

      expect(controls.dispatch(const NamedTrigger('space')), isTrue);
      expect(log, ['jump:space']);
    });

    test('several matchers reach one node, and say which arrived', () {
      controls.bind(
        node,
        'jump',
        matchers: {const NamedTrigger('space'), const NamedTrigger('up')},
      );

      controls
        ..dispatch(const NamedTrigger('up'))
        ..dispatch(const NamedTrigger('space'));

      expect(log, ['jump:up', 'jump:space'], reason: 'one bind for both events');
    });

    test('matchers from several subsystems reach one node', () {
      controls.bind(node, 'jump', matchers: {const NamedTrigger('space'), const ButtonTrigger(3)});

      expect(controls.dispatch(const ButtonTrigger(3)), isTrue);
      expect(log, ['jump:button3'], reason: 'dispatch is event-agnostic');
    });

    test('an event nothing matches runs nothing', () {
      controls.bind(node, 'jump', matchers: {const NamedTrigger('space')});

      expect(controls.dispatch(const NamedTrigger('enter')), isFalse);
      expect(log, isEmpty);
    });

    test('an event of another kind never matches', () {
      controls.bind(node, 'jump', matchers: {const NamedTrigger('space')});

      expect(controls.dispatch(const ButtonTrigger(3)), isFalse);
    });

    test('with nothing bound at all, dispatch reports unhandled', () {
      expect(controls.dispatch(const NamedTrigger('space')), isFalse);
    });

    test('an empty matcher set can never be reached', () {
      controls.bind(node, 'unreachable', matchers: const {});

      expect(controls.dispatch(const NamedTrigger('space')), isFalse);
      expect(log, isEmpty);
    });

    test('the set is copied, so the caller cannot reach in and change it', () {
      final matchers = {const NamedTrigger('space')};
      controls.bind(node, 'jump', matchers: matchers);

      matchers.add(const NamedTrigger('enter'));

      expect(controls.dispatch(const NamedTrigger('enter')), isFalse);
    });
  });

  group('lifetime', () {
    test('releasing stops the node answering', () {
      controls.bind(node, 'jump', matchers: {const NamedTrigger('space')});

      expect(controls.dispatch(const NamedTrigger('space')), isTrue);

      controls.release(node);

      expect(controls.dispatch(const NamedTrigger('space')), isFalse);
      expect(log, ['jump:space'], reason: 'it ran once, before the release');
    });

    test('releasing twice is harmless', () {
      controls.bind(node, 'jump', matchers: {const NamedTrigger('space')});
      controls.release(node);

      expect(() => controls.release(node), returnsNormally);
    });
  });

  group('precedence', () {
    test('one event runs one bind, however many match', () {
      controls
        ..bind(node, 'confirm', matchers: {const NamedTrigger('enter')})
        ..bind(node, 'cancel', matchers: {const NamedTrigger('enter')});

      expect(controls.dispatch(const NamedTrigger('enter')), isTrue);
      expect(log, ['cancel:enter'], reason: 'only the most recent');
    });

    test('releasing the winner falls back to the one beneath', () {
      controls.bind(node, 'world', matchers: {const NamedTrigger('enter')});
      controls.bind(above, 'dialog', matchers: {const NamedTrigger('enter')});

      controls.dispatch(const NamedTrigger('enter'));
      controls.release(above);
      controls.dispatch(const NamedTrigger('enter'));

      expect(log, ['dialog:enter', 'world:enter']);
    });

    test('a node masks another whose matchers it does not share', () {
      controls
        ..bind(node, 'world', matchers: {const NamedTrigger('enter'), const NamedTrigger('space')})
        ..bind(above, 'dialog', matchers: {const NamedTrigger('enter')});

      controls.dispatch(const NamedTrigger('enter'));
      controls.dispatch(const NamedTrigger('space'));

      expect(
        log,
        ['dialog:enter', 'world:space'],
        reason: 'the dialog takes only what it matches, and masks nothing else',
      );
    });
  });

  group('groups', () {
    test('a bind in no group always answers', () {
      controls.bind(node, 'jump', matchers: {const NamedTrigger('space')});

      expect(controls.dispatch(const NamedTrigger('space')), isTrue);
    });

    test('a group is enabled until it is not', () {
      controls.bind(
        node,
        'jump',
        matchers: {const NamedTrigger('space')},
        groups: {'ground'},
      );

      expect(controls.isEnabled('ground'), isTrue);
      expect(controls.dispatch(const NamedTrigger('space')), isTrue);
    });

    test('disabling one stops its binds answering', () {
      controls.bind(
        node,
        'jump',
        matchers: {const NamedTrigger('space')},
        groups: {'ground'},
      );
      controls.disable('ground');

      expect(controls.isEnabled('ground'), isFalse);
      expect(controls.dispatch(const NamedTrigger('space')), isFalse);
      expect(log, isEmpty);
    });

    test('enabling one lets them answer again', () {
      controls.bind(
        node,
        'jump',
        matchers: {const NamedTrigger('space')},
        groups: {'ground'},
      );

      controls
        ..disable('ground')
        ..enable('ground');

      expect(controls.dispatch(const NamedTrigger('space')), isTrue);
    });

    test('a bind in two groups survives one going dead', () {
      controls.bind(
        node,
        'move',
        matchers: {const NamedTrigger('left')},
        groups: {'ground', 'aerial'},
      );
      controls.disable('aerial');

      expect(
        controls.dispatch(const NamedTrigger('left')),
        isTrue,
        reason: 'ground still holds it',
      );
    });

    test('it dies only when every group holding it does', () {
      controls.bind(
        node,
        'move',
        matchers: {const NamedTrigger('left')},
        groups: {'ground', 'aerial'},
      );

      controls.disable('ground');
      expect(controls.dispatch(const NamedTrigger('left')), isTrue);

      controls.disable('aerial');
      expect(controls.dispatch(const NamedTrigger('left')), isFalse);
    });

    test('swapping two groups swaps which binds answer', () {
      controls
        ..bind(
          node,
          'move',
          matchers: {const NamedTrigger('left')},
          groups: {'ground', 'aerial'},
        )
        ..bind(
          node,
          'jump',
          matchers: {const NamedTrigger('space')},
          groups: {'ground'},
        )
        ..bind(
          node,
          'airDash',
          matchers: {const NamedTrigger('shift')},
          groups: {'aerial'},
        )
        ..disable('aerial');

      controls
        ..disable('ground')
        ..enable('aerial');

      expect(
        controls.dispatch(const NamedTrigger('space')),
        isFalse,
        reason: 'grounded jump is gone',
      );
      expect(
        controls.dispatch(const NamedTrigger('shift')),
        isTrue,
        reason: 'the air dash woke up',
      );
      expect(controls.dispatch(const NamedTrigger('left')), isTrue, reason: 'move is in both');
    });

    test('a disabled group is skipped, so the one beneath it answers', () {
      controls
        ..bind(node, 'world', matchers: {const NamedTrigger('enter')})
        ..bind(
          above,
          'dialog',
          matchers: {const NamedTrigger('enter')},
          groups: {'ui'},
        )
        ..disable('ui');

      controls.dispatch(const NamedTrigger('enter'));

      expect(log, ['world:enter'], reason: 'the event falls through');
    });

    test('a group can be switched before anything is in it', () {
      controls.disable('ground');
      controls.bind(
        node,
        'jump',
        matchers: {const NamedTrigger('space')},
        groups: {'ground'},
      );

      expect(
        controls.dispatch(const NamedTrigger('space')),
        isFalse,
        reason: 'the group switch is independent of binds',
      );
    });
  });

  group('reentrancy', () {
    test('a node can bind while it answers', () {
      final answering = TestNode(
        processor: (_, event) {
          if (event is! Control) return;
          controls.bind(above, 'crouch', matchers: {const NamedTrigger('ctrl')});
          log.add('rebound');
        },
      );

      final scene = answering.mount();
      controls.bind(answering, 'jump', matchers: {const NamedTrigger('space')});

      expect(() => controls.dispatch(const NamedTrigger('space')), returnsNormally);
      expect(log, ['rebound']);
      scene.destroy();
    });

    test('a node can release its bind while it answers', () {
      final answering = TestNode(
        processor: (node, event) {
          if (event is! Control) return;
          controls.release(node);
          log.add('once');
        },
      );

      final scene = answering.mount();
      controls.bind(answering, 'jump', matchers: {const NamedTrigger('space')});

      expect(() => controls.dispatch(const NamedTrigger('space')), returnsNormally);
      expect(controls.dispatch(const NamedTrigger('space')), isFalse);
      expect(log, ['once']);
      scene.destroy();
    });

    test('a node binding a matcher for the event it answers does not rerun it', () {
      final answering = TestNode(
        processor: (_, event) {
          if (event is! Control) return;
          controls.bind(above, 'later', matchers: {const NamedTrigger('space')});
          log.add('first');
        },
      );

      final scene = answering.mount();
      controls.bind(answering, 'jump', matchers: {const NamedTrigger('space')});
      controls.dispatch(const NamedTrigger('space'));

      expect(log, ['first'], reason: 'the match was found before the winner ran');
      scene.destroy();
    });
  });

  group('devices', () {
    test('disposing drops every control and every group switch', () {
      final controls = Controls()
        ..bind(
          node,
          'jump',
          matchers: {const NamedTrigger('space')},
          groups: {'ground'},
        )
        ..disable('ground')
        ..dispose();

      expect(controls.dispatch(const NamedTrigger('space')), isFalse);
      expect(controls.isEnabled('ground'), isTrue);
      expect(controls.devices, isEmpty);
    });
  });
}
