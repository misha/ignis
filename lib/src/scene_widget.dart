import 'package:flutter/widgets.dart';
import 'package:ignis/src/node.dart';
import 'package:ignis/src/scene_render_box.dart';

class SceneWidget extends StatefulWidget {
  final Scene scene;
  final Color color;
  final bool paused;
  final bool debug;
  final bool autofocus;
  final bool addRepaintBoundary;

  const SceneWidget(
    this.scene, {
    super.key,
    this.color = const Color(0xFF000000),
    this.paused = false,
    this.debug = false,
    this.autofocus = true,
    this.addRepaintBoundary = true,
  });

  @override
  State<SceneWidget> createState() => _SceneWidgetState();
}

class _SceneWidgetState extends State<SceneWidget> {
  late FocusNode _focusNode;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.autofocus) _focusNode.requestFocus();
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(context) {
    return Focus(
      focusNode: _focusNode,
      autofocus: widget.autofocus,
      descendantsAreFocusable: true,
      child: DecoratedBox(
        decoration: BoxDecoration(color: widget.color),
        child: LayoutBuilder(
          builder: (context, constraints) {
            final size = constraints.biggest;
            if (size.isEmpty) return const SizedBox.expand();
            widget.scene.resize(size.width, size.height);

            // Primes the tree with an initial update before the first real
            // frame tick, so the first paint reflects update()-driven setup
            // rather than one frame of stale state.
            widget.scene.update(0);

            return RenderSceneWidget(
              scene: widget.scene,
              paused: widget.paused,
              debug: widget.debug,
              addRepaintBoundary: widget.addRepaintBoundary,
            );
          },
        ),
      ),
    );
  }
}
