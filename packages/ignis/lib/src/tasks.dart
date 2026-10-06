part of 'core.dart';

final class _ReparentTask extends Task {
  final Node node;
  final Node? parent;

  _ReparentTask(this.node, this.parent);

  @override
  void execute() => node._reparent(parent);
}

final class _ReorderTask extends Task {
  final Node node;
  final int priority;

  _ReorderTask(this.node, this.priority);

  @override
  void execute() => node._reorder(priority);
}
