import 'package:ignis/src/bounds.dart';
import 'package:ignis/src/intersection_system.dart';
import 'package:ignis/src/math.dart';
import 'package:ignis/src/nodes/collider_node.dart';

/// A sweep-and-prune collision arena, run once per tick.
///
/// Registered colliders are broadphased with a sort-and-sweep over their
/// AABBs to produce candidate pairs, which are then narrowphased against
/// their actual shapes to power the node signals.
final class CollisionDetection {
  /// Used for narrowphase intersection tests.
  final IntersectionSystem system;

  /// Densely stores colliders in registration order.
  final List<ColliderNode> _colliders = [];

  /// Maps colliders to their assigned slots.
  final Map<ColliderNode, int> _mapping = .identity();

  /// Sparsely stores colliders at exactly the index of their slot.
  final List<ColliderNode?> _colliderIndex = [];

  /// Sparsely stores each collider's AABB at exactly the index of their slot.
  final List<Aabb2?> _boundsIndex = [];

  /// Slots that are not currently in use and may be reassigned.
  final List<int> _freeSlots = [];

  /// The current sort ordering for slots. The order changes each sweep.
  final List<int> _order = [];

  /// Sparsely stores each slot's index within [_order].
  final List<int> _orderIndex = [];

  /// Whether or not [_order] is currently sorted.
  bool _sorted = true;

  /// Pairs confirmed overlapping as of the last [process], by key.
  final Map<int, (ColliderNode, ColliderNode)> _overlapping = {};

  CollisionDetection({
    IntersectionSystem? system,
  }) : system = system ?? const StandardIntersectionSystem();

  void add(ColliderNode collider) {
    assert(
      !_mapping.containsKey(collider),
      'Collider is already registered.',
    );

    final int slot;

    if (_freeSlots.isNotEmpty) {
      // Reuse a free slot.
      slot = _freeSlots.removeLast();
      _colliderIndex[slot] = collider;
      _orderIndex[slot] = -1;
    } else {
      // Create a new slot.
      slot = _colliderIndex.length;
      _colliderIndex.add(collider);
      _boundsIndex.add(Aabb2());
      _orderIndex.add(-1);
    }

    _colliders.add(collider);
    _mapping[collider] = slot;
    _sorted = false;
  }

  void remove(ColliderNode collider) {
    _colliders.remove(collider);
    final slot = _mapping.remove(collider);
    if (slot == null) return;
    final index = _orderIndex[slot];

    if (index != -1) {
      _order.removeAt(index);
      _reorder(index);
    }

    _colliderIndex[slot] = null;
    _freeSlots.add(slot);
  }

  void process() {
    _sort();
    _detect();
  }

  // #region Sorting

  void _sort() {
    if (!_sorted) {
      _order.clear();

      for (final collider in _colliders) {
        final slot = _mapping[collider]!;
        final bounds = _boundsIndex[slot]!;

        computeWorldBounds(
          collider,
          collider.shape,
          bounds.mutate(),
          collider.cd,
        );

        _order.add(slot);
      }

      _order.sort(_compareLefts);
      _reorder();
      _sorted = true;
    } else {
      for (final collider in _colliders) {
        final slot = _mapping[collider]!;
        final bounds = _boundsIndex[slot]!;

        computeWorldBounds(
          collider,
          collider.shape,
          bounds.mutate(),
          collider.cd,
        );

        _resettle(slot);
      }
    }
  }

  void _reorder([int from = 0]) {
    for (var i = from; i < _order.length; i += 1) {
      _orderIndex[_order[i]] = i;
    }
  }

  double _left(int slot) => _boundsIndex[slot]!.min.x;
  int _compareLefts(int a, int b) => _left(a).compareTo(_left(b));

  void _resettle(int slot) {
    var i = _orderIndex[slot];
    final left = _left(slot);

    while (i > 0 && _left(_order[i - 1]) > left) {
      _swap(i, i - 1);
      i -= 1;
    }

    while (i < _order.length - 1 && _left(_order[i + 1]) < left) {
      _swap(i, i + 1);
      i += 1;
    }
  }

  void _swap(int i, int j) {
    final a = _order[i];
    final b = _order[j];
    _order[i] = b;
    _order[j] = a;
    _orderIndex[a] = j;
    _orderIndex[b] = i;
  }

  // #endregion

  // #region Detection

  void _detect() {
    // Not faster to make it an instance variable.
    final current = <int, (ColliderNode, ColliderNode)>{};

    for (var i = 0; i < _order.length; i += 1) {
      final slotA = _order[i];
      final a = _colliderIndex[slotA]!;
      final boundsA = _boundsIndex[slotA]!;

      for (var j = i + 1; j < _order.length; j += 1) {
        final slotB = _order[j];
        final b = _colliderIndex[slotB]!;
        final boundsB = _boundsIndex[slotB]!;

        // Broadphase:

        if (!boundsA.overlapsX(boundsB)) break;
        if (!boundsA.overlapsY(boundsB)) continue;

        // Masking:

        final aSeesB = (a.mask & b.layer) != 0;
        final bSeesA = (b.mask & a.layer) != 0;
        if (!aSeesB && !bSeesA) continue;

        // Narrowphase:

        final overlapping = switch ((a.shape, b.shape)) {
          (.rectangle, .rectangle) => true, // Proven by broadphase.
          (.circle, .circle) => system.circleCircle(boundsA, boundsB),
          (.circle, .rectangle) => system.circleRectangle(boundsA, boundsB),
          (.rectangle, .circle) => system.circleRectangle(boundsB, boundsA),
        };

        if (!overlapping) continue;

        // At this point, we have a collision. The question is: what to report?

        // Use a canonical ordering for this pair based on their slot order,
        // so the key and the stored collider order stay stable even if the
        // sweep visits them in the opposite order on a later tick.
        final int key;
        final (ColliderNode, ColliderNode) next;

        if (slotA < slotB) {
          key = _makeKey(slotA, slotB);
          next = (a, b);
        } else {
          key = _makeKey(slotB, slotA);
          next = (b, a);
        }

        current[key] = next;
        final previous = _overlapping[key];

        if (previous == null || !_identicalPair(previous, next)) {
          if (aSeesB) a.onCollisionStart.emit(b);
          if (bSeesA) b.onCollisionStart.emit(a);
        }
      }
    }

    for (final entry in _overlapping.entries) {
      final previous = entry.value;
      final next = current[entry.key];
      if (next != null && _identicalPair(previous, next)) continue;
      final (a, b) = previous;

      // A pair can end up here because a member was unregistered (e.g.
      // detached) rather than because it stopped overlapping; the arena
      // already dropped it from consideration, so just drop it silently
      // instead of firing a spurious exit.
      if (!a.isMounted || !b.isMounted) continue;
      if ((a.mask & b.layer) != 0) a.onCollisionEnd.emit(b);
      if ((b.mask & a.layer) != 0) b.onCollisionEnd.emit(a);
    }

    _overlapping
      ..clear()
      ..addAll(current);
  }

  // Limit is 53 bits for JavaScript compatibility, so keys split the space
  // down the middle, 26 bits per slot.
  static int _makeKey(int first, int second) => (first << 26) | second;

  static bool _identicalPair((ColliderNode, ColliderNode) x, (ColliderNode, ColliderNode) y) =>
      identical(x.$1, y.$1) && identical(x.$2, y.$2);
}
