import 'package:flutter/widgets.dart' hide FadeTransition, SlideTransition;
import 'package:ignis/ignis.dart';

import '../colors.dart';
import '../demo_scene.dart';

/// The demos on the Transitions page, by the name their `<Demo/>` slot carries.
final Map<String, Widget Function()> transitionsDemos = {
  'transitions-cut': () {
    return DemoScene(builder: _CutNode.new);
  },
  'transitions-curtain': () {
    return DemoScene(builder: _CurtainNode.new);
  },
  'transitions-wipe': () {
    return DemoScene(builder: _WipeNode.new);
  },
  'transitions-slide': () {
    return DemoScene(builder: _SlideNode.new);
  },
  'transitions-fade': () {
    return DemoScene(builder: _FadeNode.new);
  },
};

/// Two screens traded on every tap, with no animation between them.
class _CutNode extends Node {
  // demo on transitions-cut
  late RouterNode router;
  late int state;

  RouteNode buildRoute(Color color) {
    return RouteNode(
      transition: CutTransition(),
      children: [
        ShapeNode(paint: Paint()..color = color),
      ],
    );
  }

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        router = RouterNode(children: [buildRoute(RED)]);
        state = 0;
        final taps = TapInput(shape: .rectangle(DEMO_SIZE));
        addAll([router, taps]);

      case Tap():
        state += 1;
        router.go(buildRoute(state.isEven ? RED : GREEN));
    }
  }
  // demo off
}

/// The same trade, through a fade to black and back.
class _CurtainNode extends Node {
  // demo on transitions-curtain
  late RouterNode router;
  late int state;

  RouteNode buildRoute(Color color) {
    return RouteNode(
      transition: CurtainTransition(
        veil: () => ShapeNode(paint: Paint()..color = BLACK),
      ),
      children: [
        ShapeNode(paint: Paint()..color = color),
      ],
    );
  }

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        router = RouterNode(children: [buildRoute(RED)]);
        state = 0;
        final taps = TapInput(shape: .rectangle(DEMO_SIZE));
        addAll([router, taps]);

      case Tap():
        state += 1;
        router.go(buildRoute(state.isEven ? RED : GREEN));
    }
  }
  // demo off
}

/// A panel that sweeps across, trading the screens under full cover.
class _WipeNode extends Node {
  // demo on transitions-wipe
  late RouterNode router;
  late int state;

  RouteNode buildRoute(Color color) {
    return RouteNode(
      transition: WipeTransition(
        panel: () => ShapeNode(paint: Paint()..color = BLACK),
      ),
      children: [
        ShapeNode(paint: Paint()..color = color),
      ],
    );
  }

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        router = RouterNode(children: [buildRoute(RED)]);
        state = 0;
        final taps = TapInput(shape: .rectangle(DEMO_SIZE));
        addAll([router, taps]);

      case Tap():
        state += 1;
        router.go(buildRoute(state.isEven ? RED : GREEN));
    }
  }
  // demo off
}

/// The incoming screen slides in and pushes the outgoing one out ahead of it.
class _SlideNode extends Node {
  // demo on transitions-slide
  late RouterNode router;
  late int state;

  RouteNode buildRoute(Color color) {
    return RouteNode(
      transition: SlideTransition(),
      children: [
        ShapeNode(paint: Paint()..color = color),
      ],
    );
  }

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        router = RouterNode(children: [buildRoute(RED)]);
        state = 0;
        final taps = TapInput(shape: .rectangle(DEMO_SIZE));
        addAll([router, taps]);

      case Tap():
        state += 1;
        router.go(buildRoute(state.isEven ? RED : GREEN));
    }
  }
  // demo off
}

/// The two screens crossfade, either direction.
class _FadeNode extends Node {
  // demo on transitions-fade
  late RouterNode router;
  late int state;

  RouteNode buildRoute(Color color) {
    return RouteNode(
      transition: FadeTransition(crossFade: true),
      children: [
        ShapeNode(paint: Paint()..color = color),
      ],
    );
  }

  @override
  void process(Message message) {
    super.process(message);

    switch (message) {
      case Build():
        router = RouterNode(children: [buildRoute(RED)]);
        state = 0;
        final taps = TapInput(shape: .rectangle(DEMO_SIZE));
        addAll([router, taps]);

      case Tap():
        state += 1;
        router.go(buildRoute(state.isEven ? RED : GREEN));
    }
  }
  // demo off
}
