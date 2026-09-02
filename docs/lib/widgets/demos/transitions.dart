import 'package:flutter/widgets.dart';
import 'package:ignis/ignis.dart';

import '../demo_scene.dart';

const _EMBER = Color(0xFFFF4B33);
const _SPARK = Color(0xFFFFC53D);

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

/// A screen-filling panel of one color.
ShapeNode _screen(Color color) {
  return ShapeNode(
    shape: .rectangle(DEMO_SIZE),
    paint: Paint()..color = color,
  );
}

/// Two screens traded on every tap, with no animation between them.
class _CutNode extends Node {
  @override
  void build() {
    super.build();

    // demo on transitions-cut
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));
    final ember = _screen(_EMBER);
    final spark = _screen(_SPARK);
    SpatialNode top = add(ember);

    taps.onTap(() {
      final from = top;
      final to = identical(from, ember) ? spark : ember;
      add(to);
      top = to;
      taps.disable();

      add(
        CutTransitionEffect(to, from, cleanup: true)..onFinish(() {
          remove(from);
          taps.enable();
        }),
      );
    });
    // demo off

    add(taps);
  }
}

/// The same trade, through a fade to black and back.
class _CurtainNode extends Node {
  @override
  void build() {
    super.build();

    // demo on transitions-curtain
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));
    final ember = _screen(_EMBER);
    final spark = _screen(_SPARK);
    SpatialNode top = add(ember);

    taps.onTap(() {
      final from = top;
      final to = identical(from, ember) ? spark : ember;
      add(to);
      top = to;
      taps.disable();

      add(
        CurtainTransitionEffect(to, from, cleanup: true)..onFinish(() {
          remove(from);
          taps.enable();
        }),
      );
    });
    // demo off

    add(taps);
  }
}

/// A panel that sweeps across, swapping the screens under full cover.
class _WipeNode extends Node {
  @override
  void build() {
    super.build();

    // demo on transitions-wipe
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));
    final ember = _screen(_EMBER);
    final spark = _screen(_SPARK);
    SpatialNode top = add(ember);

    taps.onTap(() {
      final from = top;
      final to = identical(from, ember) ? spark : ember;
      add(to);
      top = to;
      taps.disable();

      add(
        WipeTransitionEffect(to, from, cleanup: true)..onFinish(() {
          remove(from);
          taps.enable();
        }),
      );
    });
    // demo off

    add(taps);
  }
}

/// The incoming screen slides in and pushes the outgoing one out ahead of it.
class _SlideNode extends Node {
  @override
  void build() {
    super.build();

    // demo on transitions-slide
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));
    final ember = _screen(_EMBER);
    final spark = _screen(_SPARK);
    SpatialNode top = add(ember);

    taps.onTap(() {
      final from = top;
      final to = identical(from, ember) ? spark : ember;
      add(to);
      top = to;
      taps.disable();

      add(
        SlideTransitionEffect(to, from, cleanup: true)..onFinish(() {
          remove(from);
          taps.enable();
        }),
      );
    });
    // demo off

    add(taps);
  }
}

/// The incoming screen fades in as one layer over the outgoing one.
class _FadeNode extends Node {
  @override
  void build() {
    super.build();

    // demo on transitions-fade
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));
    final ember = _screen(_EMBER);
    final spark = _screen(_SPARK);
    SpatialNode top = add(ember);

    taps.onTap(() {
      final from = top;
      final to = identical(from, ember) ? spark : ember;
      add(to);
      top = to;
      taps.disable();

      add(
        FadeTransitionEffect(to, from, cleanup: true)..onFinish(() {
          remove(from);
          taps.enable();
        }),
      );
    });
    // demo off

    add(taps);
  }
}
