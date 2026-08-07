import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ignis/ignis.dart';

import '../hooks.dart';

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

const _ZONE_COLOR = Colors.white24;
const _ZONE_HOVER_COLOR = Colors.white38;
const _ZONE_FILLED_COLOR = Colors.greenAccent;
const _PIECE_COLOR = Colors.orangeAccent;

//
// Collision Parameters
//

const _PIECE_LAYER = 1 << 0;
const _ZONE_LAYER = 1 << 1;

class DragAndDropDemoStory extends HookWidget {
  const DragAndDropDemoStory();

  @override
  Widget build(context) {
    final version$ = useState(0);
    final debug$ = useState(false);
    final status$ = useState('Drag the square into a zone.');

    final version = version$.value;
    final debug = debug$.value;
    final status = status$.value;
    final node = useMemoized(() => _DemoNode(), [version]);
    useSignal1(node.onStatus, (value) => status$.value = value);

    return SizedBox(
      width: _BOARD_SIZE,
      child: Focus(
        autofocus: true,
        onKeyEvent: (node, event) {
          if (event is! KeyDownEvent) {
            return .ignored;
          }

          switch (event.logicalKey) {
            case .keyR:
              version$.value += 1;

            case .keyQ:
              debug$.value = !debug;

            default:
              return .ignored;
          }

          return .handled;
        },
        child: Column(
          spacing: 5,
          mainAxisAlignment: .center,
          children: [
            Text(status),
            SizedBox(
              width: _BOARD_SIZE,
              height: _BOARD_SIZE,
              child: SceneWidget(node.mount(), debug: debug),
            ),
            Text('q=${debug ? 'debug off' : 'debug on'} | r=restart'),
          ],
        ),
      ),
    );
  }
}

class _DemoNode extends Node {
  final onStatus = Signal1<String>();

  _DemoNode() {
    late final _PieceNode piece;

    addAll([
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
    ]);

    piece.onDropped((zone) {
      if (zone == null) {
        onStatus.emit('Missed! Drag it into a zone.');
      } else {
        zone.fill();
        onStatus.emit('Dropped in a zone.');
      }
    });
  }
}

class _DropZoneNode extends ShapeNode {
  bool filled = false;

  _DropZoneNode({
    required super.position,
  }) : super(
         shape: .rectangle,
         size: .all(_ZONE_SIZE),
         anchor: .center(),
         paint: Paint()..color = _ZONE_COLOR,
       ) {
    add(
      ColliderNode(
        shape: shape,
        size: size,
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
  final onDropped = Signal1<_DropZoneNode?>();

  final Set<_DropZoneNode> _active = {};

  _PieceNode({
    required super.position,
  }) : super(
         shape: .rectangle,
         size: .all(_PIECE_SIZE),
         anchor: .center(),
         paint: Paint()..color = _PIECE_COLOR,
       ) {
    late final DragInput drags;
    late final ColliderNode collider;

    addAll([
      drags = DragInput(
        shape: shape,
        size: size + .all(_PIECE_HIT_PADDING * 2),
        anchor: anchor,
      ),
      collider = ColliderNode(
        shape: shape,
        size: size,
        anchor: anchor,
        layer: _PIECE_LAYER,
        mask: _ZONE_LAYER,
      ),
    ]);

    drags
      ..onDragUpdate((event) => position.mutate().add(event.delta))
      ..onDragEnd((_) => drop())
      ..onDragCancel(drop);

    collider
      ..onCollisionStart((other) {
        final target = other.parent;

        switch (target) {
          case _DropZoneNode():
            _active.add(target);
            target.setHighlighted(true);
        }
      })
      ..onCollisionEnd((other) {
        final target = other.parent;

        switch (target) {
          case _DropZoneNode():
            _active.remove(target);
            target.setHighlighted(false);
        }
      });
  }

  void drop() {
    final zone = _active.nearest(position);
    if (zone != null) position.mutate().setFrom(zone.position);
    onDropped.emit(zone);
  }
}
