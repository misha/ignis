import 'package:flutter/widgets.dart' hide FadeTransition, Router, SlideTransition;
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
  @override
  void build() {
    super.build();

    // demo on transitions-cut
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    final router = Router<String>(transition: CutTransition());

    final host = RouterNode(
      router: router,
      children: [
        RouteNode(
          name: 'red',
          children: [ShapeNode(paint: Paint()..color = RED)],
        ),
        RouteNode(
          name: 'green',
          children: [ShapeNode(paint: Paint()..color = GREEN)],
        ),
      ],
    );

    taps.onTap(() {
      router.go(router.top == 'red' ? 'green' : 'red');
    });
    // demo off

    addAll([host, taps]);
  }
}

/// The same trade, through a fade to black and back. Tapping mid-swap turns
/// it around.
class _CurtainNode extends Node {
  @override
  void build() {
    super.build();

    // demo on transitions-curtain
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    final router = Router<String>(
      transition: CurtainTransition(
        veil: ShapeNode(
          paint: Paint()..color = INK,
        ),
      ),
    );

    final host = RouterNode(
      router: router,
      children: [
        RouteNode(
          name: 'red',
          children: [ShapeNode(paint: Paint()..color = RED)],
        ),
        RouteNode(
          name: 'green',
          children: [ShapeNode(paint: Paint()..color = GREEN)],
        ),
      ],
    );

    taps.onTap(() {
      router.go(router.top == 'red' ? 'green' : 'red');
    });
    // demo off

    addAll([host, taps]);
  }
}

/// A panel that sweeps across, trading the screens under full cover.
class _WipeNode extends Node {
  @override
  void build() {
    super.build();

    // demo on transitions-wipe
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    final router = Router<String>(
      transition: WipeTransition(
        panel: ShapeNode(
          paint: Paint()..color = INK,
        ),
      ),
    );

    final host = RouterNode(
      router: router,
      children: [
        RouteNode(
          name: 'red',
          children: [ShapeNode(paint: Paint()..color = RED)],
        ),
        RouteNode(
          name: 'green',
          children: [ShapeNode(paint: Paint()..color = GREEN)],
        ),
      ],
    );

    taps.onTap(() {
      router.go(router.top == 'red' ? 'green' : 'red');
    });
    // demo off

    addAll([host, taps]);
  }
}

/// The incoming screen slides in and pushes the outgoing one out ahead of it.
class _SlideNode extends Node {
  @override
  void build() {
    super.build();

    // demo on transitions-slide
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    final router = Router<String>(transition: SlideTransition());

    final host = RouterNode(
      router: router,
      children: [
        RouteNode(
          name: 'red',
          children: [ShapeNode(paint: Paint()..color = RED)],
        ),
        RouteNode(
          name: 'green',
          children: [ShapeNode(paint: Paint()..color = GREEN)],
        ),
      ],
    );

    taps.onTap(() {
      router.go(router.top == 'red' ? 'green' : 'red');
    });
    // demo off

    addAll([host, taps]);
  }
}

/// The two screens crossfade, either direction.
class _FadeNode extends Node {
  @override
  void build() {
    super.build();

    // demo on transitions-fade
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    final router = Router<String>(transition: FadeTransition(crossFade: true));

    final host = RouterNode(
      router: router,
      children: [
        RouteNode(
          name: 'red',
          children: [ShapeNode(paint: Paint()..color = RED)],
        ),
        RouteNode(
          name: 'green',
          children: [ShapeNode(paint: Paint()..color = GREEN)],
        ),
      ],
    );

    taps.onTap(() {
      router.go(router.top == 'red' ? 'green' : 'red');
    });
    // demo off

    addAll([host, taps]);
  }
}
