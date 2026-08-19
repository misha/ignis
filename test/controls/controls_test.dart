import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

/// The simplest event there is: a name, matching the one that shares it.
final class _Event implements ControlEvent {
  final String name;

  const _Event(this.name);

  @override
  bool accepts(ControlEvent emitted) => emitted is _Event && emitted.name == name;

  @override
  bool operator ==(Object other) => other is _Event && other.name == name;

  @override
  int get hashCode => name.hashCode;

  @override
  String toString() => name;
}

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
      controls.bind(note('jump'), matchers: {const _Event('space')});

      expect(controls.dispatch(const _Event('space')), isTrue);
      expect(log, ['jump:space']);
    });

    test('several matchers reach one handler, and say which arrived', () {
      controls.bind(note('jump'), matchers: {const _Event('space'), const _Event('up')});

      controls
        ..dispatch(const _Event('up'))
        ..dispatch(const _Event('space'));

      expect(log, ['jump:up', 'jump:space'], reason: 'one handler, either way in');
    });

    test('matchers from several subsystems reach one handler', () {
      controls.bind(note('jump'), matchers: {const _Event('space'), const _Button(3)});

      expect(controls.dispatch(const _Button(3)), isTrue);
      expect(log, ['jump:button3'], reason: 'the engine never learns what a button is');
    });

    test('an event nothing matches runs nothing', () {
      controls.bind(note('jump'), matchers: {const _Event('space')});

      expect(controls.dispatch(const _Event('enter')), isFalse);
      expect(log, isEmpty);
    });

    test('an event of another kind never matches', () {
      controls.bind(note('jump'), matchers: {const _Event('space')});

      expect(controls.dispatch(const _Button(3)), isFalse);
    });

    test('with nothing bound at all, dispatch reports unhandled', () {
      expect(controls.dispatch(const _Event('space')), isFalse);
    });

    test('an empty matcher set can never be reached', () {
      controls.bind(note('unreachable'), matchers: const {});

      expect(controls.dispatch(const _Event('space')), isFalse);
      expect(log, isEmpty);
    });

    test('the set is copied, so the caller cannot reach in and change it', () {
      final matchers = {const _Event('space')};
      controls.bind(note('jump'), matchers: matchers);

      matchers.add(const _Event('enter'));

      expect(controls.dispatch(const _Event('enter')), isFalse);
    });
  });

  group('lifetime', () {
    test('releasing stops the handler answering', () {
      final release = controls.bind(note('jump'), matchers: {const _Event('space')});

      expect(controls.dispatch(const _Event('space')), isTrue);

      release();

      expect(controls.dispatch(const _Event('space')), isFalse);
      expect(log, ['jump:space'], reason: 'it ran once, before the release');
    });

    test('releasing twice is harmless', () {
      final release = controls.bind(note('jump'), matchers: {const _Event('space')});
      release();

      expect(release, returnsNormally);
    });
  });

  group('precedence', () {
    test('one event runs one handler, however many match', () {
      controls
        ..bind(note('confirm'), matchers: {const _Event('enter')})
        ..bind(note('cancel'), matchers: {const _Event('enter')});

      expect(controls.dispatch(const _Event('enter')), isTrue);
      expect(log, ['cancel:enter'], reason: 'the most recent of them, and only it');
    });

    test('releasing the winner falls back to the one beneath', () {
      controls.bind(note('world'), matchers: {const _Event('enter')});
      final dialog = controls.bind(note('dialog'), matchers: {const _Event('enter')});

      controls.dispatch(const _Event('enter'));
      dialog();
      controls.dispatch(const _Event('enter'));

      expect(log, ['dialog:enter', 'world:enter']);
    });

    test('a handler masks another whose matchers it does not share', () {
      controls
        ..bind(note('world'), matchers: {const _Event('enter'), const _Event('space')})
        ..bind(note('dialog'), matchers: {const _Event('enter')});

      controls.dispatch(const _Event('enter'));
      controls.dispatch(const _Event('space'));

      expect(
        log,
        ['dialog:enter', 'world:space'],
        reason: 'the dialog takes only what it matches, and masks nothing else',
      );
    });
  });

  group('groups', () {
    test('a handler in no group always answers', () {
      controls.bind(note('jump'), matchers: {const _Event('space')});

      expect(controls.dispatch(const _Event('space')), isTrue);
    });

    test('a group is enabled until it is not', () {
      controls.bind(
        note('jump'),
        matchers: {const _Event('space')},
        groups: {'ground'},
      );

      expect(controls.isEnabled('ground'), isTrue);
      expect(controls.dispatch(const _Event('space')), isTrue);
    });

    test('disabling one stops its handlers answering', () {
      controls.bind(
        note('jump'),
        matchers: {const _Event('space')},
        groups: {'ground'},
      );
      controls.disable('ground');

      expect(controls.isEnabled('ground'), isFalse);
      expect(controls.dispatch(const _Event('space')), isFalse);
      expect(log, isEmpty);
    });

    test('enabling one lets them answer again', () {
      controls.bind(
        note('jump'),
        matchers: {const _Event('space')},
        groups: {'ground'},
      );

      controls
        ..disable('ground')
        ..enable('ground');

      expect(controls.dispatch(const _Event('space')), isTrue);
    });

    test('a handler in two groups survives one going dead', () {
      controls.bind(
        note('move'),
        matchers: {const _Event('left')},
        groups: {'ground', 'aerial'},
      );
      controls.disable('aerial');

      expect(controls.dispatch(const _Event('left')), isTrue, reason: 'ground still holds it');
    });

    test('it dies only when every group holding it does', () {
      controls.bind(
        note('move'),
        matchers: {const _Event('left')},
        groups: {'ground', 'aerial'},
      );

      controls.disable('ground');
      expect(controls.dispatch(const _Event('left')), isTrue);

      controls.disable('aerial');
      expect(controls.dispatch(const _Event('left')), isFalse);
    });

    test('swapping two groups swaps which handlers answer', () {
      controls
        ..bind(
          note('move'),
          matchers: {const _Event('left')},
          groups: {'ground', 'aerial'},
        )
        ..bind(
          note('jump'),
          matchers: {const _Event('space')},
          groups: {'ground'},
        )
        ..bind(
          note('airDash'),
          matchers: {const _Event('shift')},
          groups: {'aerial'},
        )
        ..disable('aerial');

      controls
        ..disable('ground')
        ..enable('aerial');

      expect(controls.dispatch(const _Event('space')), isFalse, reason: 'grounded jump is gone');
      expect(controls.dispatch(const _Event('shift')), isTrue, reason: 'the air dash woke up');
      expect(controls.dispatch(const _Event('left')), isTrue, reason: 'move is in both');
    });

    test('a disabled group is skipped, so the one beneath it answers', () {
      controls
        ..bind(note('world'), matchers: {const _Event('enter')})
        ..bind(
          note('dialog'),
          matchers: {const _Event('enter')},
          groups: {'ui'},
        )
        ..disable('ui');

      controls.dispatch(const _Event('enter'));

      expect(log, ['world:enter'], reason: 'gone, rather than swallowing the event');
    });

    test('a group can be switched before anything is in it', () {
      controls.disable('ground');
      controls.bind(
        note('jump'),
        matchers: {const _Event('space')},
        groups: {'ground'},
      );

      expect(
        controls.dispatch(const _Event('space')),
        isFalse,
        reason: 'the switch outlives whatever happens to be bound',
      );
    });
  });

  group('reentrancy', () {
    test('a handler can bind while it answers', () {
      controls.bind((_) {
        controls.bind(note('crouch'), matchers: {const _Event('ctrl')});
        log.add('rebound');
      }, matchers: {const _Event('space')});

      expect(() => controls.dispatch(const _Event('space')), returnsNormally);
      expect(log, ['rebound']);
    });

    test('a handler can release itself while it answers', () {
      late Cleanup release;

      release = controls.bind((_) {
        release();
        log.add('once');
      }, matchers: {const _Event('space')});

      expect(() => controls.dispatch(const _Event('space')), returnsNormally);
      expect(controls.dispatch(const _Event('space')), isFalse);
      expect(log, ['once']);
    });

    test('a handler binding a matcher for the event it answers does not rerun it', () {
      controls.bind((_) {
        controls.bind(note('later'), matchers: {const _Event('space')});
        log.add('first');
      }, matchers: {const _Event('space')});

      controls.dispatch(const _Event('space'));

      expect(log, ['first'], reason: 'the match was found before the winner ran');
    });
  });

  group('devices', () {
    test('disposing drops every control and every group switch', () {
      final controls = Controls()
        ..bind(
          note('jump'),
          matchers: {const _Event('space')},
          groups: {'ground'},
        )
        ..disable('ground')
        ..dispose();

      expect(controls.dispatch(const _Event('space')), isFalse);
      expect(controls.isEnabled('ground'), isTrue);
      expect(controls.devices, isEmpty);
    });
  });
}

/// An event no keyboard could produce, to prove matching never assumes one.
final class _Button implements ControlEvent {
  final int id;

  const _Button(this.id);

  @override
  bool accepts(ControlEvent emitted) => emitted is _Button && emitted.id == id;

  @override
  String toString() => 'button$id';
}
