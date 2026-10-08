import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import '../support/test_device.dart';
import '../support/test_sink.dart';

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
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        Ignis.controls.bind(
          this,
          name,
          matchers: {
            const TestTrigger(),
          },
        );

      case Control():
        log.add(name);
    }
  }
}

/// A node whose build binds an event.
final class _Binder extends Node {
  final void Function() onJump;

  _Binder(this.onJump);

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        Ignis.controls.bind(
          this,
          'jump',
          matchers: {
            const TestTrigger(),
          },
        );

      case Control():
        onJump();
    }
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    Ignis.controls = Controls();
  });

  bool press() {
    return Ignis.controls.dispatch(const TestTrigger());
  }

  test('a bind made in build answers once the node is mounted', () {
    var jumps = 0;
    final scene = _Binder(() => jumps += 1).mount();

    expect(press(), isTrue);
    expect(jumps, 1);
    scene.destroy();
  });

  test('the bind dies with the node', () {
    var jumps = 0;
    final node = _Binder(() => jumps += 1);
    final scene = Node(children: [node]).mount();

    node.detach();
    scene.update(0);

    expect(press(), isFalse);
    expect(jumps, 0);
    scene.destroy();
  });

  test('a bind made outside a build is the caller to release', () {
    final sink = TestSink();
    final scene = sink.mount();

    Ignis.controls.bind(
      sink,
      'jump',
      matchers: {
        const TestTrigger(),
      },
    );

    expect(press(), isTrue);
    Ignis.controls.release(sink);
    expect(press(), isFalse);
    expect(sink.of<Control>(), hasLength(1));
    scene.destroy();
  });

  group('tree order', () {
    late List<String> log;

    setUp(() => log = []);

    test('the topmost sibling wins', () {
      final scene = Node(
        children: [
          _Answers('under', log),
          _Answers('over', log, priority: 1),
        ],
      ).mount();

      press();

      expect(log, ['over'], reason: 'reverse priority, as a hit test walks it');
      scene.destroy();
    });

    test('a child beats its parent', () {
      final scene = _Answers('parent', log, children: [_Answers('child', log)]).mount();

      press();

      expect(log, ['child']);
      scene.destroy();
    });

    test('a disabled node is skipped, and the one beneath answers', () {
      final over = _Answers('over', log, priority: 1);
      final scene = Node(children: [_Answers('under', log), over]).mount();

      press();
      expect(log, ['over']);

      over.enabled = false;
      press();

      expect(log, ['over', 'under'], reason: 'a disabled node is skipped; its bind stays');
      scene.destroy();
    });

    test('a disabled node answers nothing, even uncontested', () {
      final only = _Answers('only', log);
      final scene = Node(children: [only]).mount();

      press();
      expect(log, ['only']);

      only.enabled = false;

      expect(press(), isFalse);
      expect(log, ['only'], reason: 'the walk never reaches it');
      scene.destroy();
    });

    test('the most recently mounted scene wins', () {
      final first = _Answers('first', log).mount();
      final second = _Answers('second', log).mount();

      press();
      expect(log, ['second']);

      second.destroy();
      press();

      expect(log, ['second', 'first']);
      first.destroy();
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
      scene.destroy();
    });

    test('a group gates a node bind like any other', () {
      final scene = Node(children: [_Answers('under', log), _Gated('over', log)]).mount();

      press();
      expect(log, ['over'], reason: 'topmost, and its group is enabled');

      Ignis.controls.disable('ui');
      press();

      expect(log, ['over', 'under'], reason: 'the press falls through');
      scene.destroy();
    });
  });
}

/// A node whose bind sits in a group, so it can be switched off from outside.
final class _Gated extends Node {
  final String name;
  final List<String> log;

  _Gated(this.name, this.log) : super(priority: 1);

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        Ignis.controls.bind(
          this,
          name,
          matchers: {const TestTrigger()},
          groups: {'ui'},
        );

      case Control():
        log.add(name);
    }
  }
}
