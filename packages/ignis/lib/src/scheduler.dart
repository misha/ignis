// SPDX-AI-Disclosure: none

import 'dart:collection';

import 'package:flutter/foundation.dart';

@internal
final class Task {
  final VoidCallback _callback;

  Task(this._callback);

  /// Runs the callback on [scheduler].
  ///
  /// If [scheduler] is null, the callback is executed immediately.
  void run(Scheduler? scheduler) {
    if (scheduler != null) {
      scheduler.schedule(this);
    } else {
      _callback();
    }
  }
}

@internal
final class Scheduler {
  final _tasks = Queue<Task>();

  void schedule(Task task) {
    _tasks.add(task);
  }

  void flush() {
    while (_tasks.isNotEmpty) {
      _tasks.removeFirst()._callback();
    }
  }
}
