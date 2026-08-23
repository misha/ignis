import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

/// The simplest event there is: it matches its own kind.
final class _Event implements ControlEvent {
  const _Event();

  @override
  bool accepts(ControlEvent emitted) => emitted is _Event;
}

/// A node whose build binds the event, logging its name when it answers.
final class _Answers extends Node {
  final String name;
  final List<String> log;

  _Answers(
    this.name,
    this.log, {
    super.priority,
    super.children,
  });

  @override
  void build() {
    super.build();
    Ignis.controls.bind((_) => log.add(name), matchers: {const _Event()});
  }
}

/// A node whose build binds an event, and which can be rebuilt on demand.
final class _Binder extends Node with Live {
  final void Function() onJump;
  int builds = 0;

  _Binder(this.onJump);

  @override
  void build() {
    super.build();
    builds += 1;
    Ignis.controls.bind((_) => onJump(), matchers: {const _Event()});
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => Ignis.controls = Controls());

  bool press() => Ignis.controls.dispatch(const _Event());

  test('a bind made in build answers once the node is mounted', () {
    var jumps = 0;
    _Binder(() => jumps += 1).mount();

    expect(press(), isTrue);
    expect(jumps, 1);
  });

  test('a rebuild replaces the bind rather than stacking one', () {
    var jumps = 0;
    final node = _Binder(() => jumps += 1);
    final scene = node.mount();

    scene.reassemble();
    expect(node.builds, 2, reason: 'the node rebuilt');

    press();
    expect(jumps, 1, reason: 'the old bind was trashed, so only one ran');
  });

  test('the bind dies with the node', () {
    var jumps = 0;
    final node = _Binder(() => jumps += 1);
    final scene = Node(children: [node]).mount();

    node.detach();
    scene.update(0);

    expect(press(), isFalse);
    expect(jumps, 0);
  });

  test('a bind made outside a build is the caller to release', () {
    var jumps = 0;
    final release = Ignis.controls.bind((_) => jumps += 1, matchers: {const _Event()});

    expect(press(), isTrue);
    release();
    expect(press(), isFalse);
    expect(jumps, 1);
  });

  group('tree order', () {
    late List<String> log;

    setUp(() => log = []);

    test('the topmost sibling wins', () {
      Node(
        children: [
          _Answers('under', log),
          _Answers('over', log, priority: 1),
        ],
      ).mount();

      press();

      expect(log, ['over'], reason: 'reverse priority, as a hit test walks it');
    });

    test('a child beats its parent', () {
      _Answers('parent', log, children: [_Answers('child', log)]).mount();

      press();

      expect(log, ['child']);
    });

    test('a disabled node is skipped, and the one beneath answers', () {
      final over = _Answers('over', log, priority: 1);
      Node(children: [_Answers('under', log), over]).mount();

      press();
      expect(log, ['over']);

      over.enabled = false;
      press();

      expect(log, ['over', 'under'], reason: 'the bind is still there, the node is not');
    });

    test('a disabled node answers nothing, even uncontested', () {
      final only = _Answers('only', log);
      Node(children: [only]).mount();

      press();
      expect(log, ['only']);

      only.enabled = false;

      expect(press(), isFalse);
      expect(log, ['only'], reason: 'the walk never reaches it');
    });

    test('any node beats a bind made outside a build', () {
      Ignis.controls.bind((_) => log.add('loose'), matchers: {const _Event()});
      _Answers('node', log).mount();

      press();

      expect(log, ['node']);
    });

    test('the most recently mounted scene wins', () {
      _Answers('first', log).mount();
      final second = _Answers('second', log).mount();

      press();
      expect(log, ['second']);

      second.destroy();
      press();

      expect(log, ['second', 'first']);
    });

    test('releasing the winner falls back to the node beneath', () {
      final over = _Answers('over', log, priority: 1);
      final scene = Node(children: [_Answers('under', log), over]).mount();

      press();
      expect(log, ['over']);

      over.detach();
      scene.update(0);

      press();

      expect(log, ['over', 'under']);
    });

    test('a group gates a node bind like any other', () {
      Node(children: [_Answers('under', log), _Gated('over', log)]).mount();

      press();
      expect(log, ['over'], reason: 'topmost, and its group is enabled');

      Ignis.controls.disable('ui');
      press();

      expect(log, ['over', 'under'], reason: 'gone, rather than swallowing the press');
    });
  });
}

/// A node whose bind sits in a group, so it can be switched off from outside.
final class _Gated extends Node {
  final String name;
  final List<String> log;

  _Gated(this.name, this.log) : super(priority: 1);

  @override
  void build() {
    super.build();
    Ignis.controls.bind(
      (_) => log.add(name),
      matchers: {const _Event()},
      groups: {'ui'},
    );
  }
}
