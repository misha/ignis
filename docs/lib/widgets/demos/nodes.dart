import 'package:flutter/widgets.dart';
import 'package:ignis/ignis.dart';

import '../colors.dart';
import '../demo_scene.dart';

const _CENTER = Vector2.all(62.5);

/// The demos on the Nodes page, by the name their `<Demo/>` slot carries.
final Map<String, Widget Function()> nodeDemos = {
  'node-priority-order': () => DemoScene(builder: _OrderNode.new),
  'node-priority-lifted': () => DemoScene(builder: _LiftedNode.new),
  'node-priority-nested': () => DemoScene(builder: _NestedNode.new),
  'node-enabled': () => DemoScene(builder: _EnabledNode.new),
};

ShapeNode _circle() {
  return ShapeNode(
    shape: .circle(20),
    paint: Paint()..color = RED,
    position: Vector2(-10, -10),
    anchor: .center,
  );
}

ShapeNode _box() {
  return ShapeNode(
    shape: .square(40),
    paint: Paint()..color = BLUE,
    position: Vector2(10, 10),
    anchor: .center,
  );
}

ShapeNode _dot(Color color) {
  return ShapeNode(
    shape: .circle(20),
    paint: Paint()..color = color,
  );
}

/// The two shapes as siblings, on the default priority.
class _OrderNode extends SpatialNode {
  _OrderNode() : super(position: _CENTER);

  @override
  void build() {
    super.build();

    final circle = _circle();
    final box = _box();

    // demo on node-priority-order
    add(circle);
    add(box);
    // demo off
  }
}

/// The same two, with the one added first lifted over the other.
class _LiftedNode extends SpatialNode {
  _LiftedNode() : super(position: _CENTER);

  @override
  void build() {
    super.build();

    final circle = _circle();
    final box = _box();

    // demo on node-priority-lifted
    add(circle..priority = 1);
    add(box);
    // demo off
  }
}

/// The same two, with the circle hanging off a box that vastly outranks it.
class _NestedNode extends SpatialNode {
  _NestedNode() : super(position: _CENTER);

  @override
  void build() {
    super.build();

    final circle = _circle();
    final box = _box();

    // demo on node-priority-nested
    add(box..priority = 1000);
    box.add(circle);
    // demo off
  }
}

/// Two dots side by side, one of them switched in and out by a tap.
class _EnabledNode extends Node {
  @override
  void build() {
    super.build();

    final green = _dot(GREEN);
    final red = _dot(RED);
    final taps = TapInput(shape: .rectangle(DEMO_SIZE));

    // demo on node-enabled
    red.enabled = false;

    taps.onTap(() {
      red.enabled = !red.enabled;
    });
    // demo off

    addAll([
      BoxNode(
        alignment: .center,
        children: [
          RowNode(
            mainAxisSize: .min,
            crossAxisAlignment: .center,
            spacing: 16,
            children: [green, red],
          ),
        ],
      ),
      taps,
    ]);
  }
}
