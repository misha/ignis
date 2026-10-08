part of 'core.dart';

final class _ReparentTask extends Task {
  final Entity entity;
  final Entity? parent;

  _ReparentTask(this.entity, this.parent);

  @override
  void execute() => entity._reparent(parent);
}

final class _ReorderTask extends Task {
  final Entity entity;
  final int priority;

  _ReorderTask(this.entity, this.priority);

  @override
  void execute() => entity._reorder(priority);
}

final class _AttachTask extends Task {
  final Component component;
  final Entity? entity;

  _AttachTask(this.component, this.entity);

  @override
  void execute() => component._attach(entity);
}
