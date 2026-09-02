import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_device.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Controls controls;
  late List<String> log;

  setUp(() {
    controls = Controls();
    log = [];
  });

  ControlHandler note(String name) {
    return (event) => log.add('$name:$event');
  }

  group('binding', () {
    test('reaches its handler, with the event that got there', () {
      controls.bind(note('jump'), matchers: {const NamedEvent('space')});

      expect(controls.dispatch(const NamedEvent('space')), isTrue);
      expect(log, ['jump:space']);
    });

    test('several matchers reach one handler, and say which arrived', () {
      controls.bind(note('jump'), matchers: {const NamedEvent('space'), const NamedEvent('up')});

      controls
        ..dispatch(const NamedEvent('up'))
        ..dispatch(const NamedEvent('space'));

      expect(log, ['jump:up', 'jump:space'], reason: 'one handler, either way in');
    });

    test('matchers from several subsystems reach one handler', () {
      controls.bind(note('jump'), matchers: {const NamedEvent('space'), const ButtonEvent(3)});

      expect(controls.dispatch(const ButtonEvent(3)), isTrue);
      expect(log, ['jump:button3'], reason: 'the engine never learns what a button is');
    });

    test('an event nothing matches runs nothing', () {
      controls.bind(note('jump'), matchers: {const NamedEvent('space')});

      expect(controls.dispatch(const NamedEvent('enter')), isFalse);
      expect(log, isEmpty);
    });

    test('an event of another kind never matches', () {
      controls.bind(note('jump'), matchers: {const NamedEvent('space')});

      expect(controls.dispatch(const ButtonEvent(3)), isFalse);
    });

    test('with nothing bound at all, dispatch reports unhandled', () {
      expect(controls.dispatch(const NamedEvent('space')), isFalse);
    });

    test('an empty matcher set can never be reached', () {
      controls.bind(note('unreachable'), matchers: const {});

      expect(controls.dispatch(const NamedEvent('space')), isFalse);
      expect(log, isEmpty);
    });

    test('the set is copied, so the caller cannot reach in and change it', () {
      final matchers = {const NamedEvent('space')};
      controls.bind(note('jump'), matchers: matchers);

      matchers.add(const NamedEvent('enter'));

      expect(controls.dispatch(const NamedEvent('enter')), isFalse);
    });
  });

  group('lifetime', () {
    test('releasing stops the handler answering', () {
      final release = controls.bind(note('jump'), matchers: {const NamedEvent('space')});

      expect(controls.dispatch(const NamedEvent('space')), isTrue);

      release();

      expect(controls.dispatch(const NamedEvent('space')), isFalse);
      expect(log, ['jump:space'], reason: 'it ran once, before the release');
    });

    test('releasing twice is harmless', () {
      final release = controls.bind(note('jump'), matchers: {const NamedEvent('space')});
      release();

      expect(release, returnsNormally);
    });
  });

  group('precedence', () {
    test('one event runs one handler, however many match', () {
      controls
        ..bind(note('confirm'), matchers: {const NamedEvent('enter')})
        ..bind(note('cancel'), matchers: {const NamedEvent('enter')});

      expect(controls.dispatch(const NamedEvent('enter')), isTrue);
      expect(log, ['cancel:enter'], reason: 'the most recent of them, and only it');
    });

    test('releasing the winner falls back to the one beneath', () {
      controls.bind(note('world'), matchers: {const NamedEvent('enter')});
      final dialog = controls.bind(note('dialog'), matchers: {const NamedEvent('enter')});

      controls.dispatch(const NamedEvent('enter'));
      dialog();
      controls.dispatch(const NamedEvent('enter'));

      expect(log, ['dialog:enter', 'world:enter']);
    });

    test('a handler masks another whose matchers it does not share', () {
      controls
        ..bind(note('world'), matchers: {const NamedEvent('enter'), const NamedEvent('space')})
        ..bind(note('dialog'), matchers: {const NamedEvent('enter')});

      controls.dispatch(const NamedEvent('enter'));
      controls.dispatch(const NamedEvent('space'));

      expect(
        log,
        ['dialog:enter', 'world:space'],
        reason: 'the dialog takes only what it matches, and masks nothing else',
      );
    });
  });

  group('groups', () {
    test('a handler in no group always answers', () {
      controls.bind(note('jump'), matchers: {const NamedEvent('space')});

      expect(controls.dispatch(const NamedEvent('space')), isTrue);
    });

    test('a group is enabled until it is not', () {
      controls.bind(
        note('jump'),
        matchers: {const NamedEvent('space')},
        groups: {'ground'},
      );

      expect(controls.isEnabled('ground'), isTrue);
      expect(controls.dispatch(const NamedEvent('space')), isTrue);
    });

    test('disabling one stops its handlers answering', () {
      controls.bind(
        note('jump'),
        matchers: {const NamedEvent('space')},
        groups: {'ground'},
      );
      controls.disable('ground');

      expect(controls.isEnabled('ground'), isFalse);
      expect(controls.dispatch(const NamedEvent('space')), isFalse);
      expect(log, isEmpty);
    });

    test('enabling one lets them answer again', () {
      controls.bind(
        note('jump'),
        matchers: {const NamedEvent('space')},
        groups: {'ground'},
      );

      controls
        ..disable('ground')
        ..enable('ground');

      expect(controls.dispatch(const NamedEvent('space')), isTrue);
    });

    test('a handler in two groups survives one going dead', () {
      controls.bind(
        note('move'),
        matchers: {const NamedEvent('left')},
        groups: {'ground', 'aerial'},
      );
      controls.disable('aerial');

      expect(controls.dispatch(const NamedEvent('left')), isTrue, reason: 'ground still holds it');
    });

    test('it dies only when every group holding it does', () {
      controls.bind(
        note('move'),
        matchers: {const NamedEvent('left')},
        groups: {'ground', 'aerial'},
      );

      controls.disable('ground');
      expect(controls.dispatch(const NamedEvent('left')), isTrue);

      controls.disable('aerial');
      expect(controls.dispatch(const NamedEvent('left')), isFalse);
    });

    test('swapping two groups swaps which handlers answer', () {
      controls
        ..bind(
          note('move'),
          matchers: {const NamedEvent('left')},
          groups: {'ground', 'aerial'},
        )
        ..bind(
          note('jump'),
          matchers: {const NamedEvent('space')},
          groups: {'ground'},
        )
        ..bind(
          note('airDash'),
          matchers: {const NamedEvent('shift')},
          groups: {'aerial'},
        )
        ..disable('aerial');

      controls
        ..disable('ground')
        ..enable('aerial');

      expect(
        controls.dispatch(const NamedEvent('space')),
        isFalse,
        reason: 'grounded jump is gone',
      );
      expect(controls.dispatch(const NamedEvent('shift')), isTrue, reason: 'the air dash woke up');
      expect(controls.dispatch(const NamedEvent('left')), isTrue, reason: 'move is in both');
    });

    test('a disabled group is skipped, so the one beneath it answers', () {
      controls
        ..bind(note('world'), matchers: {const NamedEvent('enter')})
        ..bind(
          note('dialog'),
          matchers: {const NamedEvent('enter')},
          groups: {'ui'},
        )
        ..disable('ui');

      controls.dispatch(const NamedEvent('enter'));

      expect(log, ['world:enter'], reason: 'gone, rather than swallowing the event');
    });

    test('a group can be switched before anything is in it', () {
      controls.disable('ground');
      controls.bind(
        note('jump'),
        matchers: {const NamedEvent('space')},
        groups: {'ground'},
      );

      expect(
        controls.dispatch(const NamedEvent('space')),
        isFalse,
        reason: 'the switch outlives whatever happens to be bound',
      );
    });
  });

  group('reentrancy', () {
    test('a handler can bind while it answers', () {
      controls.bind((_) {
        controls.bind(note('crouch'), matchers: {const NamedEvent('ctrl')});
        log.add('rebound');
      }, matchers: {const NamedEvent('space')});

      expect(() => controls.dispatch(const NamedEvent('space')), returnsNormally);
      expect(log, ['rebound']);
    });

    test('a handler can release itself while it answers', () {
      late Cleanup release;

      release = controls.bind((_) {
        release();
        log.add('once');
      }, matchers: {const NamedEvent('space')});

      expect(() => controls.dispatch(const NamedEvent('space')), returnsNormally);
      expect(controls.dispatch(const NamedEvent('space')), isFalse);
      expect(log, ['once']);
    });

    test('a handler binding a matcher for the event it answers does not rerun it', () {
      controls.bind((_) {
        controls.bind(note('later'), matchers: {const NamedEvent('space')});
        log.add('first');
      }, matchers: {const NamedEvent('space')});

      controls.dispatch(const NamedEvent('space'));

      expect(log, ['first'], reason: 'the match was found before the winner ran');
    });
  });

  group('devices', () {
    test('disposing drops every control and every group switch', () {
      final controls = Controls()
        ..bind(
          note('jump'),
          matchers: {const NamedEvent('space')},
          groups: {'ground'},
        )
        ..disable('ground')
        ..dispose();

      expect(controls.dispatch(const NamedEvent('space')), isFalse);
      expect(controls.isEnabled('ground'), isTrue);
      expect(controls.devices, isEmpty);
    });
  });
}
