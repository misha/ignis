// SPDX-AI-Disclosure: none

import 'dart:ui';

import 'package:ignis/src/math.dart';

/// Paints one of a [Palette]'s entries to the canvas.
typedef Painter = void Function(Canvas canvas, Paint paint);

/// A named [Paint] entry, registered with a [Palette] via [Palette.add].
///
/// [paint] is never reassigned; mutate its properties directly instead.
class PaletteEntry {
  Palette? _palette;

  /// This paint's key in its owning [Palette], or null for the default paint.
  final String? name;

  /// The paint drawn for this entry.
  final Paint paint;

  /// Where this paint is drawn, relative to its node's origin. Defaults to
  /// the origin.
  final Vector2 offset;

  int _priority;

  /// This paint's order among its siblings. Defaults to 0.
  int get priority => _priority;

  set priority(int value) {
    _priority = value;
    _palette?._reposition(this);
  }

  /// Whether this paint is drawn. Defaults to true.
  bool enabled;

  /// Creates a named paint entry, to be registered with [Palette.add].
  PaletteEntry(
    String this.name,
    this.paint, {
    Vector2? offset,
    int? priority,
    bool? enabled,
  }) : offset = offset ?? .zero,
       _priority = priority ?? 0,
       enabled = enabled ?? true;

  PaletteEntry._default(this.paint)
    : name = null, //
      offset = .zero,
      _priority = 0,
      enabled = true;
}

/// A managed, ordered collection of named [Paint]s.
///
/// A [Palette] always holds at least one paint: the default, reached via
/// [paint]. Additional paints may be registered with [add], each with its own
/// offset and priority, letting a single node configure any number of paints.
class Palette {
  late final PaletteEntry _default;
  final List<PaletteEntry> _paints = [];
  final Map<String, PaletteEntry> _index = {};

  /// The default paint. Always present.
  Paint get paint => _default.paint;

  /// The paint registered under [name].
  Paint operator [](String name) => entry(name).paint;

  /// All registered paints, including the default, in ascending priority
  /// order. Includes disabled paints.
  Iterable<PaletteEntry> get entries => _paints;

  Palette({
    Paint? paint,
  }) {
    _default = PaletteEntry._default(paint ?? Paint());
    _default._palette = this;
    _paints.add(_default);
  }

  /// Calls [painter] once per enabled paint, in ascending priority order, with
  /// [canvas] translated to that entry's offset and back again.
  ///
  /// Pass a function that already exists rather than a literal, so a node
  /// drawing every frame allocates nothing:
  ///
  /// ```dart
  /// void painter(Canvas canvas, Paint paint) { ... }
  ///
  /// draw((canvas) {
  ///   palette.draw(canvas, painter);
  /// });
  /// ```
  void draw(Canvas canvas, Painter painter) {
    for (final entry in _paints) {
      if (!entry.enabled) continue;
      final offset = entry.offset;

      if (!offset.isZero) {
        canvas.translate(offset.x, offset.y);
        painter(canvas, entry.paint);
        canvas.translate(-offset.x, -offset.y);
      } else {
        painter(canvas, entry.paint);
      }
    }
  }

  /// The entry registered under [name], or the default entry if null.
  PaletteEntry entry([String? name]) {
    if (name == null) return _default;
    final entry = _index[name];
    if (entry == null) throw StateError('No paint named "$name" is registered.');
    return entry;
  }

  /// Registers [entry] in the palette, replacing whatever was registered under
  /// its name before.
  ///
  /// Throws a [StateError] if [entry] belongs to a different palette.
  PaletteEntry add(PaletteEntry entry) {
    final palette = entry._palette;

    if (palette != null && palette != this) {
      throw StateError('This entry is registered in a different palette.');
    }

    // Ensured by the public `Palette` factory.
    final name = entry.name!;
    final replaced = _index[name];

    if (replaced != null) {
      _paints.remove(replaced);
      replaced._palette = null;
    }

    entry._palette = this;
    _insert(entry);
    _index[name] = entry;
    return entry;
  }

  /// Removes the paint named [name].
  ///
  /// Returns true if it was found and removed. The default paint is not
  /// addressable and cannot be removed this way.
  bool remove(String name) {
    final entry = _index.remove(name);
    if (entry == null) return false;
    _paints.remove(entry);
    entry._palette = null;
    return true;
  }

  void _insert(PaletteEntry entry) {
    var low = 0;
    var high = _paints.length;

    while (low < high) {
      final middle = (low + high) >> 1;

      if (_paints[middle].priority <= entry.priority) {
        low = middle + 1;
      } else {
        high = middle;
      }
    }

    _paints.insert(low, entry);
  }

  void _reposition(PaletteEntry entry) {
    _paints.remove(entry);
    _insert(entry);
  }
}
