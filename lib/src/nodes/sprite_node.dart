import 'dart:ui';

import 'package:ignis/src/core.dart';
import 'package:ignis/src/debug.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/sized_node.dart';
import 'package:ignis/src/palette.dart';
import 'package:ignis/src/spritesheet.dart';

// TODO: A sheet is a uniform grid and nothing else, which is not enough. A row
// carries no parameters of its own, so a short row plays off its end and into
// the padding, and every row on a sheet animates at the one [fps] the node
// holds. Rows want their own frame count, rate, and start and end frames, and
// a frame wants a duration of its own, the way Flame's does.

/// Draws one frame of a [Spritesheet] at a time, and animates along its row.
///
/// ```dart
/// add(
///   SpriteNode(
///     sheet: .asset('assets/fire.png', .new(32, 48)),
///     fps: 12,
///   ),
/// );
/// ```
///
/// A sprite takes its [size] from the sheet's frame, so [anchor], hit testing
/// and layout all work off the frame rather than the image. [play] chooses
/// which sheet and which row is playing.
class SpriteNode extends SizedNode {
  /// This node's registered paints.
  final Palette palette;

  /// The default paint.
  Paint get paint => palette.paint;

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

  /// How many sheets this sprite can [play].
  int get sheets => _sheets.length;

  /// The sheet currently playing.
  Spritesheet get sheet => _sheets[_sheet];

  /// The frame currently drawn, indexed into [sheet].
  int get frame => _frame.floor();

  /// Whether a non-looping animation has reached its final frame.
  bool get isFinished => _finished;

  /// The size of one frame of [sheet].
  @override
  Vector2 get size => sheet.size;

  /// Creates a sprite that draws [sheet].
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
  }) : _sheets = .of([sheet], growable: false),
       palette = Palette(paint: paint),
       fps = fps ?? 0,
       loop = loop ?? true,
       cleanup = cleanup ?? false;

  /// Creates a sprite that draws one of [sheets], chosen with [play].
  ///
  /// Keeps an animation set per image - an idle sheet and a running sheet, say -
  /// rather than packing every state into one.
  // TODO: Take a frameSize here for the supplied assets to default to. An
  // animation set is cut to one size, and every sheet in it currently repeats
  // that size, which is the noisiest part of constructing one. Alternatively, a
  // SplitSpritesheet that cuts several images to a single size and hands back
  // the sheets.
  SpriteNode.split({
    required Iterable<Spritesheet> sheets,
    num? fps,
    bool? loop,
    bool? cleanup,
    Paint? paint,
    super.position,
    super.scale,
    super.angle,
    super.anchor,
    super.enabled,
    super.priority,
    super.children,
  }) : assert(sheets.isNotEmpty),
       _sheets = .of(sheets, growable: false),
       palette = Palette(paint: paint),
       fps = fps ?? 0,
       loop = loop ?? true,
       cleanup = cleanup ?? false;

  @override
  void build() {
    super.build();
    tick((dt) {
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
    });

    void painter(Canvas canvas, Paint paint) {
      final sheet = this.sheet;

      canvas.drawImageRect(
        sheet.image,
        sheet[frame],
        // TODO: Make just one of these, whenever the spritesheet changes.
        Rect.fromLTWH(0, 0, width, height),
        paint,
      );
    }

    draw((canvas) {
      palette.draw(canvas, painter);
    });

    debugDraw((canvas) {
      canvas.drawRect(.fromLTWH(0, 0, width, height), DEBUG_TRANSFORM_PAINT);
    });
  }

  /// Re-resolves every sheet through [Spritesheet.current], so an image
  /// replaced in the cache reaches the screen without rebuilding this node.
  @override
  void reassemble() {
    for (var index = 0; index < _sheets.length; index += 1) {
      _sheets[index] = _sheets[index].current;
    }

    // Clamp the current frame if the replacement is shorter.
    if (_frame >= sheet.frames) _frame = 0;
  }

  /// Plays [sheet] from the frame at [row] and [column].
  ///
  /// ```dart
  /// // Animates the second row of the running sheet.
  /// sprite.play(sheet: 1, row: 1);
  /// ```
  ///
  /// Clears [isFinished], so a non-looping sprite that already finished runs
  /// again from wherever this puts it.
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
}
