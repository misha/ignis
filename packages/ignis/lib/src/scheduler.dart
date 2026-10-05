// SPDX-AI-Disclosure: none

import 'dart:collection';

import 'package:flutter/foundation.dart';

@internal
final class Task extends LinkedListEntry<Task> {
  final void Function() call;

  Task(this.call);

  void cancel() {
    if (list == null) return;
    unlink();
  }
}

@internal
sealed class Scheduler {
  const Scheduler();

  void schedule(Task task);

  void flush() {
    // Nothing to do.
  }
}

@internal
final class ImmediateScheduler extends Scheduler {
  const ImmediateScheduler();

  @override
  void schedule(Task task) {
    task.call();
  }
}

@internal
final class QueuedScheduler extends Scheduler {
  final _tasks = LinkedList<Task>();

  @override
  void schedule(Task task) {
    _tasks.add(task);
  }

  @override
  void flush() {
    while (_tasks.isNotEmpty) {
      final task = _tasks.first..unlink();
      task.call();
    }
  }
}
