import 'dart:ui';

import 'package:ignis/src/debug.dart';
import 'package:ignis/src/nodes/sized_node.dart';
import 'package:ignis/src/signal.dart';
import 'package:ignis/src/spritesheet.dart';

class SpriteNode extends SizedNode {
  /// Passed to the canvas when drawing the sprite.
  final Paint paint;

  /// The frames per second to use when animating this sprite.
  ///
  /// Defaults to 0, or no animation. Must be >= 0.
  num fps;

  /// Whether or not this sprite loops when animating.
  ///
  /// Defaults to true, although the default 0 [fps] renders it without effect.
  bool loop;

  /// Whether to [detach] once finished. Defaults to false.
  ///
  /// Ignored when [loop] is true, since a looping sprite never finishes.
  bool cleanup;

  /// Emitted when animation advances to a new [frame].
  final onFrame = Signal1<int>();

  /// Emitted when a looping animation wraps to the start of its row.
  final onLoop = Signal0();

  /// Emitted when a non-looping animation reaches its final frame.
  final onFinish = Signal0();

  final List<Spritesheet> _sheets;
  int _sheet = 0;
  num _frame = 0;
  bool _finished = false;

  int get sheets => _sheets.length;
  Spritesheet get sheet => _sheets[_sheet];
  int get frame => _frame.floor();
  bool get isFinished => _finished;

  @override
  double get width => sheet.size.x;

  @override
  double get height => sheet.size.y;

  SpriteNode({
    required Spritesheet sheet,
    Paint? paint,
    num? fps,
    bool? loop,
    bool? cleanup,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : _sheets = .unmodifiable([sheet]),
       paint = paint ?? Paint(),
       fps = fps ?? 0,
       loop = loop ?? true,
       cleanup = cleanup ?? false;

  SpriteNode.split({
    required Iterable<Spritesheet> sheets,
    Paint? paint,
    num? fps,
    bool? loop,
    bool? cleanup,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : assert(sheets.isNotEmpty),
       _sheets = .unmodifiable(sheets),
       paint = paint ?? Paint(),
       fps = fps ?? 0,
       loop = loop ?? true,
       cleanup = cleanup ?? false;

  void play({
    int sheet = 0,
    int row = 0,
    int column = 0,
  }) {
    if (sheet < 0) {
      throw ArgumentError.value(sheet, 'sheet', 'Cannot be negative.');
    }

    if (sheet >= sheets) {
      throw ArgumentError.value(sheet, 'sheet', 'Only $sheets sheets available.');
    }

    final selected = _sheets[sheet];

    if (row < 0) {
      throw ArgumentError.value(row, 'row', 'Cannot be negative.');
    }

    if (column < 0) {
      throw ArgumentError.value(column, 'column', 'Cannot be negative.');
    }

    if (row >= selected.rows) {
      throw ArgumentError.value(
        row,
        'row',
        'The selected sheet only has ${selected.rows} rows.',
      );
    }

    if (column >= selected.columns) {
      throw ArgumentError.value(
        column,
        'column',
        'The selected sheet only has ${selected.columns} columns.',
      );
    }

    _sheet = sheet;
    _frame = row * selected.columns + column;
    _finished = false;
  }

  @override
  void tick(double dt) {
    if (_finished) return;
    final amount = fps * dt;
    if (amount <= 0 || !amount.isFinite) return;

    final row = frame ~/ sheet.columns;
    final start = row * sheet.columns;
    final column = _frame - start;
    final next = column + amount;
    var advanced = next.floor() - column.floor();

    if (!loop && next >= sheet.columns) {
      advanced = sheet.columns - 1 - column.floor();
      _finished = true;
    }

    var current = column.floor();

    while (advanced-- > 0) {
      current += 1;

      if (current == sheet.columns) {
        current = 0;
        final frame = _frame = start;
        onFrame.emit(frame);
        onLoop.emit();
      } else {
        final frame = _frame = start + current;
        onFrame.emit(frame);
      }
    }

    if (_finished) {
      _frame = start + sheet.columns - 1;
      onFinish.emit();

      if (cleanup) {
        detach();
      }
    } else {
      _frame = start + next % sheet.columns;
    }
  }

  late Rect _dest;

  @override
  void renderAnchored(Canvas canvas) {
    canvas.drawImageRect(
      sheet.image,
      sheet[frame],
      _dest = .fromLTWH(0, 0, width, height),
      paint,
    );
  }

  @override
  void debugRenderAnchored(Canvas canvas) {
    canvas.drawRect(_dest, DEBUG_TRANSFORM_PAINT);
  }
}
