import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:ignis/ignis.dart';

import 'package:flutter/foundation.dart';

import '../support/test_loader.dart';
import '../support/test_bundle.dart';
import '../support/test_node.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  late TestLoader loader;

  setUp(() {
    loader = TestLoader();
    Ignis.cache.clear();
    Ignis.bundle = TestBundle();
    Ignis.preload = Preload()..register(loader);
  });

  /// Runs the event loop and the scene together until the loads settle.
  Future<void> drain(Scene scene, [int turns = 20]) async {
    for (var i = 0; i < turns; i += 1) {
      await Future<void>.delayed(Duration.zero);
      scene.update(0);
    }
  }

  void muzzle() {
    final previous = FlutterError.onError;
    FlutterError.onError = (details) {};
    addTearDown(() => FlutterError.onError = previous);
  }

  test('follows its request to completion, finishing once', () async {
    loader.gates['a.png'] = Completer<void>();
    final request = Ignis.preload.load(paths: ['a.png']);
    final effect = LoadingEffect(request: request);
    var finishes = 0;
    effect.onFinish(() => finishes += 1);
    final scene = Node(children: [effect]).mount();

    await drain(scene);
    expect(effect.progress, 0);
    expect(effect.isFinished, isFalse);

    loader.gates['a.png']!.complete();
    await drain(scene);
    expect(finishes, 1);
    expect(effect.isFinished, isTrue);
    expect(effect.progress, 1);
    request.dispose();
  });

  test('finishes on its first tick when handed a landed request', () async {
    final request = Ignis.preload.load(paths: ['a.png']);
    await request;
    final effect = LoadingEffect(request: request);
    final scene = Node(children: [effect]).mount();

    scene.update(0);
    expect(effect.isFinished, isTrue);
    request.dispose();
  });

  test('a disabled effect never finishes', () async {
    final effect = LoadingEffect(request: Ignis.preload.load(), enabled: false);
    final scene = Node(children: [effect]).mount();

    await drain(scene);
    expect(effect.isFinished, isFalse);
  });

  test('a one-off run serves as well as a kept request', () async {
    final request = Preload.run(loaders: [loader], paths: ['a.png']);
    final effect = LoadingEffect(request: request);
    final scene = Node(children: [effect]).mount();

    await drain(scene);
    expect(effect.isFinished, isTrue);
    expect(loader.loaded, ['a.png']);
  });

  test('a failure emits onError once and never finishes', () async {
    muzzle();
    loader.failing.add('a.png');
    final effect = LoadingEffect(request: Ignis.preload.load(paths: ['a.png']));
    final errors = <PreloadSnapshot>[];
    effect.onError(errors.add);
    final scene = Node(children: [effect]).mount();

    await drain(scene);
    expect(errors, hasLength(1));
    expect(errors.single.error, isA<StateError>());
    expect(effect.isFinished, isFalse);
    expect(effect.enabled, isFalse);
  });

  test('a cancelled request disables the effect quietly', () async {
    loader.gates['a.png'] = Completer<void>();
    final request = Ignis.preload.load(paths: ['a.png']);
    final effect = LoadingEffect(request: request);
    var finishes = 0;
    effect.onFinish(() => finishes += 1);
    final errors = <PreloadSnapshot>[];
    effect.onError(errors.add);
    final scene = Node(children: [effect]).mount();

    await drain(scene);
    request.dispose();
    loader.gates['a.png']!.complete();
    await drain(scene);

    expect(finishes, 0);
    expect(errors, isEmpty);
    expect(effect.isFinished, isFalse);
    expect(effect.enabled, isFalse);
  });

  test('a sequence finishes its phases in order', () async {
    loader.gates['a.png'] = Completer<void>();
    final first = LoadingEffect(request: Ignis.preload.load(paths: ['a.png']));
    final second = LoadingEffect(request: Ignis.preload.load(paths: ['b.png']));
    final sequence = SequentialEffect(effects: [first, second]);
    var finishes = 0;
    sequence.onFinish(() => finishes += 1);
    final scene = Node(children: [sequence]).mount();

    await drain(scene);
    expect(second.progress, 1, reason: 'the pool runs every request');
    expect(second.isFinished, isFalse, reason: 'its turn has not come');
    expect(finishes, 0);

    loader.gates['a.png']!.complete();
    await drain(scene);
    expect(first.isFinished, isTrue);
    expect(second.isFinished, isTrue);
    expect(finishes, 1);
  });

  test('a combination finishes once every load has', () async {
    loader.gates['a.png'] = Completer<void>();

    final combined = CombinedEffect(
      effects: [
        LoadingEffect(request: Ignis.preload.load(paths: ['a.png'])),
        LoadingEffect(request: Ignis.preload.load(paths: ['b.png'])),
      ],
    );

    var finishes = 0;
    combined.onFinish(() => finishes += 1);
    final scene = Node(children: [combined]).mount();

    await drain(scene);
    expect(finishes, 0);

    loader.gates['a.png']!.complete();
    await drain(scene);
    expect(finishes, 1);
  });

  test('the boot recipe composes from the primitives', () async {
    Ignis.bundle = TestBundle(['world.png']);
    final boot = LoadingEffect(request: Ignis.preload.load(paths: ['ui.png']));
    final main = LoadingEffect(request: Ignis.preload.load(manifest: true));
    final host = TransitionNode<String>();
    final game = TestNode(name: 'game');
    final view = TestNode(name: 'view');
    TransitionGroupNode<String>? booting;

    boot.onFinish(() {
      booting = host.add(
        TransitionGroupNode(
          name: 'boot',
          children: [view],
        ),
      );
    });

    main.onFinish(() {
      host.add(
        TransitionGroupNode(
          name: 'game',
          children: [game],
        ),
      );
    });

    final scene = Node(
      children: [
        host,
        SequentialEffect(
          effects: [boot, main],
          cleanup: true,
        ),
      ],
    ).mount();

    await drain(scene);
    expect(loader.loaded, containsAll(['ui.png', 'world.png']));
    expect(host.shown, 'boot', reason: 'the first group to register shows');
    expect(view.isMounted, isTrue);

    host.show('game');
    await drain(scene);
    expect(host.shown, 'game');
    expect(game.isMounted, isTrue);
    expect(booting!.enabled, isFalse, reason: 'settling disabled the boot group');
  });
}
