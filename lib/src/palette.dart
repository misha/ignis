import 'dart:ui';

import 'package:ignis/src/math.dart';

/// A single named [Paint] entry managed by a [Palette].
///
/// [value] is never reassigned; mutate its properties directly instead.
class PalettePaint {
  final Palette _palette;

  /// This paint's key in its owning [Palette], or null for the default paint.
  final String? name;

  /// The paint drawn for this entry.
  final Paint value;

  /// Where this paint is drawn, relative to its node's origin. Defaults to
  /// the origin.
  final Vector2 offset;

  int _priority;

  /// This paint's order among its siblings. Defaults to 0.
  int get priority => _priority;

  set priority(int value) {
    _priority = value;
    _palette._reposition(this);
  }

  /// Whether this paint is drawn. Defaults to true.
  bool enabled;

  PalettePaint._(
    this._palette,
    this.name,
    this.value, {
    Vector2? offset,
    int? priority,
    bool? enabled,
  }) : offset = offset ?? .zero(),
       _priority = priority ?? 0,
       enabled = enabled ?? true;
}

/// A managed, ordered collection of named [Paint]s.
///
/// A [Palette] always holds at least one paint: the default, reached via
/// [paint]. Additional paints may be registered with [add], each with its own
/// offset and priority, letting a single node configure any number of paints.
///
/// TODO: Document palette usage in the README.
class Palette {
  late final PalettePaint _default;
  final List<PalettePaint> _paints = [];
  final Map<String, PalettePaint> _index = {};

  /// All registered paints, including the default, in ascending priority
  /// order. Includes disabled paints.
  Iterable<PalettePaint> get paints => _paints;

  Palette({
    required Paint paint,
  }) {
    _default = PalettePaint._(this, null, paint);
    _paints.add(_default);
  }

  /// The default paint. Always present.
  PalettePaint get paint => _default;

  /// The named paint registered via [add], or null if none exists.
  PalettePaint? operator [](String name) => _index[name];

  /// Registers a new [paint] in the palette.
  ///
  /// Throws a [StateError] if [name] is already registered.
  PalettePaint add(
    String name, {
    required Paint paint,
    Vector2? offset,
    int? priority,
    bool? enabled,
  }) {
    if (_index.containsKey(name)) {
      throw StateError('A paint named "$name" is already registered.');
    }

    final entry = PalettePaint._(
      this,
      name,
      paint,
      offset: offset,
      priority: priority,
      enabled: enabled,
    );

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
    return true;
  }

  void _insert(PalettePaint entry) {
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

  void _reposition(PalettePaint entry) {
    _paints.remove(entry);
    _insert(entry);
  }
}
