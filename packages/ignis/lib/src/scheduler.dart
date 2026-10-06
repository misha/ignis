// SPDX-AI-Disclosure: none

import 'dart:collection';

import 'package:flutter/foundation.dart';

@internal
abstract base class Task extends LinkedListEntry<Task> {
  void execute();

  void cancel() {
    if (list == null) return;
    unlink();
  }
}

@internal
mixin class Scheduler {
  final _tasks = LinkedList<Task>();

  @internal
  void schedule(Task task) {
    _tasks.add(task);
  }

  @internal
  void flush() {
    while (_tasks.isNotEmpty) {
      final task = _tasks.first..unlink();
      task.execute();
    }
  }
}
