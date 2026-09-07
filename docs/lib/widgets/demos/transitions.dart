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
  @override
  void build() {
    super.build();

    // demo on transitions-cut
    RouteNode buildRoute(Color color) {
      return RouteNode(
        transition: CutTransition(),
        children: [
          ShapeNode(paint: Paint()..color = color),
        ],
      );
    }

    final router = RouterNode(children: [buildRoute(RED)]);
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));
    int state = 0;

    taps.onTap(() {
      state += 1;
      router.go(buildRoute(state.isEven ? RED : GREEN));
    });

    addAll([router, taps]);
    // demo off
  }
}

/// The same trade, through a fade to black and back.
class _CurtainNode extends Node {
  @override
  void build() {
    super.build();

    // demo on transitions-curtain
    RouteNode buildRoute(Color color) {
      return RouteNode(
        transition: CurtainTransition(
          veil: ShapeNode(paint: Paint()..color = BLACK),
        ),
        children: [
          ShapeNode(paint: Paint()..color = color),
        ],
      );
    }

    final router = RouterNode(children: [buildRoute(RED)]);
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));
    int state = 0;

    taps.onTap(() {
      state += 1;
      router.go(buildRoute(state.isEven ? RED : GREEN));
    });

    addAll([router, taps]);
    // demo off
  }
}

/// A panel that sweeps across, trading the screens under full cover.
class _WipeNode extends Node {
  @override
  void build() {
    super.build();

    // demo on transitions-wipe
    RouteNode buildRoute(Color color) {
      return RouteNode(
        transition: WipeTransition(
          panel: ShapeNode(paint: Paint()..color = BLACK),
        ),
        children: [
          ShapeNode(paint: Paint()..color = color),
        ],
      );
    }

    final router = RouterNode(children: [buildRoute(RED)]);
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));
    int state = 0;

    taps.onTap(() {
      state += 1;
      router.go(buildRoute(state.isEven ? RED : GREEN));
    });

    addAll([router, taps]);
    // demo off
  }
}

/// The incoming screen slides in and pushes the outgoing one out ahead of it.
class _SlideNode extends Node {
  @override
  void build() {
    super.build();

    // demo on transitions-slide
    RouteNode buildRoute(Color color) {
      return RouteNode(
        transition: SlideTransition(),
        children: [
          ShapeNode(paint: Paint()..color = color),
        ],
      );
    }

    final router = RouterNode(children: [buildRoute(RED)]);
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));
    int state = 0;

    taps.onTap(() {
      state += 1;
      router.go(buildRoute(state.isEven ? RED : GREEN));
    });

    addAll([router, taps]);
    // demo off
  }
}

/// The two screens crossfade, either direction.
class _FadeNode extends Node {
  @override
  void build() {
    super.build();

    // demo on transitions-fade
    RouteNode buildRoute(Color color) {
      return RouteNode(
        transition: FadeTransition(crossFade: true),
        children: [
          ShapeNode(paint: Paint()..color = color),
        ],
      );
    }

    final router = RouterNode(children: [buildRoute(RED)]);
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));
    int state = 0;

    taps.onTap(() {
      state += 1;
      router.go(buildRoute(state.isEven ? RED : GREEN));
    });

    addAll([router, taps]);
    // demo off
  }
}
