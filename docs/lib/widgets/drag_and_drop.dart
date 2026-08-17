import 'package:flutter/widgets.dart';
import 'package:ignis/ignis.dart';

//
// Demo Parameters
//

const _BOARD_SIZE = 300.0;
const _ZONE_SIZE = 100.0;
const _ZONE_MARGIN = 15.0;
const _PIECE_SIZE = 60.0;
const _PIECE_HIT_PADDING = 10.0; // Bigger than the piece, so it's easier to grab.

//
// Visual Parameters
//

const _BOARD_COLOR = Color(0xFF14161A);
const _ZONE_COLOR = Color(0x3DFFFFFF);
const _ZONE_HOVER_COLOR = Color(0x61FFFFFF);
const _ZONE_FILLED_COLOR = Color(0xFF69F0AE);
const _PIECE_COLOR = Color(0xFFFFAB40);

//
// Collision Parameters
//

const _PIECE_LAYER = 1 << 0;
const _ZONE_LAYER = 1 << 1;

/// The drag-and-drop scene embedded in the Inputs page.
///
/// [onStatus] reports back out to the surrounding page, so the status line is
/// real HTML rather than text painted inside the scene.
class DragAndDropWidget extends StatefulWidget {
  const DragAndDropWidget({
    required this.onStatus,
    super.key,
  });

  final void Function(String status) onStatus;

  @override
  State<DragAndDropWidget> createState() => _DragAndDropWidgetState();
}

class _DragAndDropWidgetState extends State<DragAndDropWidget> {
  late final Scene<_DemoNode> scene;
  late final Cleanup _cleanup;

  @override
  void initState() {
    super.initState();
    scene = _DemoNode().mount();

    _cleanup = scene.node.onStatus((status) {
      widget.onStatus(status);
    });
  }

  @override
  void dispose() {
    // The scene itself belongs to SceneWidget, which destroys it.
    _cleanup();
    super.dispose();
  }

  @override
  Widget build(context) {
    return Center(
      child: SizedBox(
        width: _BOARD_SIZE,
        height: _BOARD_SIZE,
        // Autofocus is off on purpose. A scene embedded in a page of prose
        // must not take focus as it mounts, or it drags the reader with it.
        child: SceneWidget(
          scene,
          color: _BOARD_COLOR,
          autofocus: false,
        ),
      ),
    );
  }
}

class _DemoNode extends Node {
  /// Emitted whenever the piece is dropped, hit or miss.
  final onStatus = Signal1<String>();

  @override
  void build() {
    super.build();
    late final _PieceNode piece;

    add(
      CollisionDetectionNode(
        children: [
          _DropZoneNode(
            position: .new(
              _ZONE_MARGIN + _ZONE_SIZE / 2,
              _BOARD_SIZE - _ZONE_MARGIN - _ZONE_SIZE / 2,
            ),
          ),
          _DropZoneNode(
            position: .new(
              _BOARD_SIZE - _ZONE_MARGIN - _ZONE_SIZE / 2,
              _BOARD_SIZE - _ZONE_MARGIN - _ZONE_SIZE / 2,
            ),
          ),
          piece = _PieceNode(
            position: .new(_BOARD_SIZE / 2, _PIECE_SIZE),
          ),
        ],
      ),
    );

    piece.onDropped((zone) {
      if (zone == null) {
        onStatus.emit('Missed. Drag it onto a zone.');
        return;
      }

      zone.fill();
      onStatus.emit('Dropped in a zone.');
    });
  }
}

class _DropZoneNode extends ShapeNode {
  bool filled = false;

  _DropZoneNode({
    required super.position,
  }) : super(
         shape: .square(_ZONE_SIZE),
         anchor: .center,
         paint: Paint()..color = _ZONE_COLOR,
       );

  @override
  void build() {
    super.build();

    add(
      ColliderNode(
        shape: shape,
        anchor: anchor,
        layer: _ZONE_LAYER,
        mask: 0,
      ),
    );
  }

  void setHighlighted(bool highlighted) {
    if (filled) return;
    paint.color = highlighted ? _ZONE_HOVER_COLOR : _ZONE_COLOR;
  }

  void fill() {
    filled = true;
    paint.color = _ZONE_FILLED_COLOR;
  }
}

class _PieceNode extends ShapeNode {
  /// Emitted with the zone it landed on, or null if it landed on nothing.
  final onDropped = Signal1<_DropZoneNode?>();

  final Set<_DropZoneNode> _active = {};

  _PieceNode({
    required super.position,
  }) : super(
         shape: .square(_PIECE_SIZE),
         anchor: .center,
         paint: Paint()..color = _PIECE_COLOR,
       );

  @override
  void build() {
    super.build();

    final drags = add(
      DragInput(
        shape: .square(shape.width + _PIECE_HIT_PADDING * 2),
        anchor: anchor,
      ),
    );

    drags
      ..onDragUpdate((event) {
        position.add(event.delta);
      })
      ..onDragEnd((_) {
        drop();
      })
      ..onDragCancel(drop);

    final collider = add(
      ColliderNode(
        shape: shape,
        anchor: anchor,
        layer: _PIECE_LAYER,
        mask: _ZONE_LAYER,
      ),
    );

    collider
      ..onCollisionStart((other) {
        switch (other.parent) {
          case final _DropZoneNode zone:
            _active.add(zone);
            zone.setHighlighted(true);
        }
      })
      ..onCollisionEnd((other) {
        switch (other.parent) {
          case final _DropZoneNode zone:
            _active.remove(zone);
            zone.setHighlighted(false);
        }
      });
  }

  void drop() {
    final zone = _active.nearest(this);
    if (zone != null) position.setFrom(zone.position);
    onDropped.emit(zone);
  }
}
