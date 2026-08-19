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

/// An action a game names at runtime, out of more than one piece.
final class _PlayerAction {
  final int player;
  final String verb;

  const _PlayerAction(this.player, this.verb);

  @override
  bool operator ==(Object other) {
    return other is _PlayerAction && other.player == player && other.verb == verb;
  }

  @override
  int get hashCode => Object.hash(player, verb);
}

enum _Game { jump }

/// A node that offers its own default, and should need nothing else to.
final class _Binder extends Node {
  final List<String> log;

  _Binder(this.log);

  @override
  void build() {
    super.build();

    Ignis.controls.claim(
      'jump',
      (_) => log.add('jump'),
      matchers: {
        const _Event('space'),
      },
    );
  }
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
    return (report) => log.add('$name:${report.event ?? 'direct'}');
  }

  group('actions', () {
    test('a string names an action', () {
      controls
        ..bind('jump', {const _Event('space')})
        ..claim('jump', note('jump'));

      expect(controls.dispatch(const _Event('space')), isTrue);
      expect(log, ['jump:space']);
    });

    test('a value built at runtime names an action', () {
      controls
        ..bind(const _PlayerAction(2, 'jump'), {const _Event('space')})
        ..claim(const _PlayerAction(2, 'jump'), note('p2'));

      expect(controls.dispatch(const _Event('space')), isTrue);
      expect(log, ['p2:space'], reason: 'an equal action is the same action');
    });

    test('actions that compare unequal stay apart', () {
      controls
        ..bind(const _PlayerAction(1, 'jump'), {const _Event('space')})
        ..bind(const _PlayerAction(2, 'jump'), {const _Event('enter')})
        ..claim(const _PlayerAction(1, 'jump'), note('p1'))
        ..claim(const _PlayerAction(2, 'jump'), note('p2'));

      controls.dispatch(const _Event('enter'));

      expect(log, ['p2:enter']);
    });

    test('an enum names an action', () {
      controls
        ..bind(_Game.jump, {const _Event('space')})
        ..claim(_Game.jump, note('jump'));

      expect(controls.dispatch(const _Event('space')), isTrue);
    });

    test('an action is matched, never read', () {
      controls
        ..bind('jump', {const _Event('space')})
        ..claim('JUMP', note('shouting'));

      expect(controls.dispatch(const _Event('space')), isFalse);
      expect(log, isEmpty);
    });
  });

  group('binding', () {
    test('does nothing for a trigger nothing is bound to', () {
      controls
        ..bind('jump', {const _Event('space')})
        ..claim('jump', note('jump'));

      expect(controls.dispatch(const _Event('enter')), isFalse);
      expect(log, isEmpty);
    });

    test('does nothing for a bound trigger nothing claims', () {
      controls.bind('jump', {const _Event('space')});

      expect(controls.dispatch(const _Event('space')), isFalse);
    });

    test('carries several triggers for one action, and says which fired', () {
      controls
        ..bind('jump', {const _Event('space'), const _Event('up')})
        ..claim('jump', note('jump'));

      controls
        ..dispatch(const _Event('up'))
        ..dispatch(const _Event('space'));

      expect(log, ['jump:up', 'jump:space']);
    });

    test('rebinding replaces the old triggers', () {
      controls
        ..bind('jump', {const _Event('space')})
        ..claim('jump', note('jump'))
        ..bind('jump', {const _Event('enter')});

      expect(controls.dispatch(const _Event('space')), isFalse);
      expect(controls.dispatch(const _Event('enter')), isTrue);
    });

    test('unbinding leaves the claim unreachable', () {
      controls
        ..bind('jump', {const _Event('space')})
        ..claim('jump', note('jump'))
        ..unbind('jump');

      expect(controls.dispatch(const _Event('space')), isFalse);
    });

    test('unbinding an action that was never bound is harmless', () {
      expect(() => controls.unbind('jump'), returnsNormally);
    });
  });

  group('claiming with events', () {
    test('binds for as long as the claim lasts', () {
      final release = controls.claim('jump', note('jump'), matchers: {const _Event('space')});

      expect(controls.eventsFor('jump'), {const _Event('space')});
      expect(controls.dispatch(const _Event('space')), isTrue);

      release();

      expect(controls.eventsFor('jump'), isEmpty, reason: 'it went out with the claim');
      expect(controls.dispatch(const _Event('space')), isFalse);
    });

    test('puts back whatever was assigned before it', () {
      controls.bind('jump', {const _Event('up')});

      final release = controls.claim('jump', note('jump'), matchers: {const _Event('space')});
      expect(controls.eventsFor('jump'), {const _Event('space')});

      release();

      expect(
        controls.eventsFor('jump'),
        {const _Event('up')},
        reason: 'a passing claim does not eat the app assignment',
      );
    });

    test('a node owns the assignment along with the claim', () {
      final node = _Binder(log);
      final scene = Node(children: [node]).mount();

      expect(Ignis.controls.eventsFor('jump'), {const _Event('space')});

      node.detach();
      scene.update(0);

      expect(Ignis.controls.eventsFor('jump'), isEmpty, reason: 'no trash() of your own');
      scene.destroy();
    });
  });

  group('reentrancy', () {
    test('a handler can bind while it answers', () {
      controls
        ..bind('jump', {const _Event('space')})
        ..claim('jump', (_) {
          controls.bind('crouch', {const _Event('ctrl')});
          log.add('rebound');
        });

      expect(() => controls.dispatch(const _Event('space')), returnsNormally);
      expect(log, ['rebound']);
    });

    test('a handler can unbind another action while it answers', () {
      controls
        ..bind('confirm', {const _Event('enter')})
        ..bind('cancel', {const _Event('enter')})
        ..claim('confirm', (_) {
          controls.unbind('cancel');
          log.add('confirm');
        })
        ..claim('cancel', note('cancel'));

      expect(() => controls.dispatch(const _Event('enter')), returnsNormally);
      expect(log, contains('confirm'));
    });

    test('a handler can unbind its own action while it answers', () {
      controls
        ..bind('jump', {const _Event('space')})
        ..claim('jump', (_) {
          controls.unbind('jump');
          log.add('once');
        });

      expect(() => controls.dispatch(const _Event('space')), returnsNormally);
      expect(controls.dispatch(const _Event('space')), isFalse);
      expect(log, ['once']);
    });
  });

  group('claims', () {
    test('with no node between them, the most recent wins', () {
      controls
        ..bind('confirm', {const _Event('enter')})
        ..claim('confirm', note('first'))
        ..claim('confirm', note('second'));

      controls.dispatch(const _Event('enter'));

      expect(log, ['second:enter']);
    });

    test('releasing the winner falls back to the one beneath', () {
      controls.bind('confirm', {const _Event('enter')});
      controls.claim('confirm', note('world'));
      final dialog = controls.claim('confirm', note('dialog'));

      controls.dispatch(const _Event('enter'));
      dialog();
      controls.dispatch(const _Event('enter'));

      expect(log, ['dialog:enter', 'world:enter']);
    });

    test('a released claim never runs again', () {
      controls.bind('jump', {const _Event('space')});
      final claim = controls.claim('jump', note('jump'));
      claim();

      expect(controls.dispatch(const _Event('space')), isFalse);
    });

    test('releasing twice is harmless', () {
      controls.bind('jump', {const _Event('space')});
      final claim = controls.claim('jump', note('jump'));
      claim();

      expect(claim, returnsNormally);
    });

    test('one trigger runs the winner of every action bound to it', () {
      controls
        ..bind('confirm', {const _Event('enter')})
        ..bind('cancel', {const _Event('enter')})
        ..claim('confirm', note('confirm'))
        ..claim('cancel', note('cancel'));

      expect(controls.dispatch(const _Event('enter')), isTrue);
      expect(log, unorderedEquals(['confirm:enter', 'cancel:enter']));
    });
  });

  group('fire', () {
    test('runs the winning claim with no event at all', () {
      controls
        ..bind('jump', {const _Event('space')})
        ..claim('jump', note('jump'));

      expect(controls.fire('jump'), isTrue);
      expect(log, ['jump:direct']);
    });

    test('reaches an action nothing is bound to', () {
      controls.claim('jump', note('jump'));

      expect(controls.eventsFor('jump'), isEmpty);
      expect(controls.fire('jump'), isTrue, reason: 'no trigger stands in the way');
    });

    test('carries an event a caller makes up to say where it came from', () {
      late ControlReport seen;

      controls.claim('jump', (report) => seen = report);
      controls.fire('jump', const _Event('button'));

      expect(seen.event, const _Event('button'));
      expect(controls.eventsFor('jump'), isEmpty);
      expect(
        controls.dispatch(const _Event('button')),
        isFalse,
        reason: 'the made-up event is provenance, never a binding',
      );
    });

    test('reports false when nothing claims the action', () {
      controls.bind('jump', {const _Event('space')});

      expect(controls.fire('jump'), isFalse);
    });

    test('picks a winner like any other firing', () {
      controls
        ..claim('confirm', note('world'))
        ..claim('confirm', note('dialog'));

      controls.fire('confirm');

      expect(log, ['dialog:direct']);
    });
  });

  group('report', () {
    test('carries the action and the event that fired it', () {
      late ControlReport seen;

      controls
        ..bind('jump', {const _Event('space'), const _Event('up')})
        ..claim('jump', (report) => seen = report);

      controls.dispatch(const _Event('up'));

      expect(seen.action, 'jump');
      expect(seen.event, const _Event('up'), reason: 'which of the two fired');
    });

    test('carries the action at its own type, with no cast', () {
      late _PlayerAction seen;

      controls
        ..bind(const _PlayerAction(2, 'jump'), {const _Event('space')})
        ..claim(const _PlayerAction(2, 'jump'), (report) => seen = report.action);

      controls.dispatch(const _Event('space'));

      expect(seen.player, 2, reason: 'report.action is a _PlayerAction, not an Object');
    });

    test('carries only the action when fired directly', () {
      late ControlReport seen;

      controls
        ..bind('jump', {const _Event('space')})
        ..claim('jump', (report) => seen = report);

      controls.fire('jump');

      expect(seen.action, 'jump');
      expect(seen.event, isNull);
    });
  });

  group('bindings view', () {
    test('reports what is assigned', () {
      controls.bind('jump', {const _Event('space')});

      expect(controls.eventsFor('jump'), {const _Event('space')});
      expect(controls.eventsFor('cancel'), isEmpty);
      expect(controls.bindings.keys, ['jump']);
    });

    test('cannot be mutated through', () {
      controls.bind('jump', {const _Event('space')});

      expect(() => controls.bindings['cancel'] = {}, throwsUnsupportedError);
      expect(() => controls.eventsFor('jump').clear(), throwsUnsupportedError);

      // The sets inside the view are the live ones, so they need wrapping too.
      expect(
        () => controls.bindings['jump']!.add(const _Event('enter')),
        throwsUnsupportedError,
      );

      expect(controls.eventsFor('jump'), {const _Event('space')});
    });
  });
}
