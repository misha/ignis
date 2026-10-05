// SPDX-AI-Disclosure: none

import 'dart:collection';

import 'package:flutter/foundation.dart';

typedef Change = void Function();

@internal
sealed class Tree {
  const Tree();

  void schedule(Change change);
}

@internal
final class ImmediateTree extends Tree {
  const ImmediateTree();

  @override
  void schedule(Change change) {
    change();
  }
}

@internal
final class QueuedTree extends Tree {
  final _changes = Queue<Change>();

  @override
  void schedule(Change change) {
    _changes.addLast(change);
  }

  /// Applies every pending structural change, in enqueued order.
  void flush() {
    while (_changes.isNotEmpty) {
      _changes.removeFirst()();
    }
  }
}
