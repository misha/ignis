import 'package:flutter/widgets.dart';
import 'package:ignis/src/assets/cache.dart';
import 'package:ignis/src/core.dart';
import 'package:ignis/src/flutter/scene_render_box.dart';
import 'package:ignis/src/globals.dart';

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
  late Cache _cache;
  bool _primed = false;

  @override
  void initState() {
    super.initState();
    _focusNode = FocusNode();
    if (widget.autofocus) _focusNode.requestFocus();
    _cache = Ignis.cache;
    _cache.addListener(_reassembleAssets);
  }

  @override
  void didUpdateWidget(SceneWidget old) {
    super.didUpdateWidget(old);
    if (!identical(old.scene, widget.scene)) {
      old.scene.destroy();
      _primed = false;
    }
  }

  @override
  void dispose() {
    _cache.removeListener(_reassembleAssets);
    _focusNode.dispose();
    widget.scene.destroy();
    super.dispose();
  }

  @override
  void reassemble() {
    super.reassemble();
    widget.scene.reassemble(.reload);
  }

  void _reassembleAssets() {
    widget.scene.reassemble(.assets);
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
            if (!_primed) {
              _primed = true;
              widget.scene.update(0);
            }

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
