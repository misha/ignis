// SPDX-AI-Disclosure: none

import 'dart:collection';

import 'package:flutter/foundation.dart';

typedef Change = void Function();

@internal
sealed class Scheduler {
  const Scheduler();

  void schedule(Change change);

  void flush() {}
}

@internal
final class ImmediateScheduler extends Scheduler {
  const ImmediateScheduler();

  @override
  void schedule(Change change) {
    change();
  }
}

@internal
final class QueuedScheduler extends Scheduler {
  final _changes = Queue<Change>();

  @override
  void schedule(Change change) {
    _changes.addLast(change);
  }

  @override
  void flush() {
    while (_changes.isNotEmpty) {
      _changes.removeFirst()();
    }
  }
}
