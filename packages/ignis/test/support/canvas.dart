import 'dart:ui';

/// A canvas that records every rect drawn onto it, the paint's color at the
/// time of each draw, every rect clipped to, and how many layers were taken;
/// every other call is swallowed.
final class RecordingCanvas implements Canvas {
  final rects = <Rect>[];
  final colors = <Color>[];
  final clips = <Rect>[];
  int saveLayers = 0;

  @override
  void drawRect(Rect rect, Paint paint) {
    rects.add(rect);
    colors.add(paint.color);
  }

  @override
  void saveLayer(Rect? bounds, Paint paint) {
    saveLayers += 1;
  }

  @override
  void clipRect(
    Rect rect, {
    ClipOp clipOp = ClipOp.intersect,
    bool doAntiAlias = true,
  }) {
    clips.add(rect);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => null;
}
