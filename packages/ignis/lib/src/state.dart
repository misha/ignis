part of 'core.dart';

sealed class _State {
  const _State();

  Node? get parent => null;

  Scene? get scene => null;

  Tree get tree => const ImmediateTree();
}

final class _Detached extends _State {
  const _Detached();

  @override
  String toString() => 'detached';
}

final class _Attached extends _State {
  @override
  final Node parent;

  const _Attached(this.parent);

  @override
  String toString() => 'attached';
}

final class _Root extends _State {
  @override
  final Scene scene;

  const _Root(this.scene);

  @override
  Tree get tree => scene.tree;

  @override
  String toString() => 'root';
}

final class _Mounted extends _State {
  @override
  final Node parent;

  @override
  final Scene scene;

  const _Mounted(this.parent, this.scene);

  @override
  Tree get tree => scene.tree;

  @override
  String toString() => 'mounted';
}

final class _Arriving extends _State {
  final Node target;

  const _Arriving(this.target);

  @override
  String toString() => 'arriving';
}

final class _Moving extends _State {
  final Node from;
  final Node target;

  @override
  final Scene scene;

  const _Moving(this.from, this.target, this.scene);

  @override
  Node get parent => from;

  @override
  Tree get tree => scene.tree;

  @override
  String toString() => 'moving';
}

final class _Removing extends _State {
  @override
  final Node parent;

  @override
  final Scene scene;

  const _Removing(this.parent, this.scene);

  @override
  Tree get tree => scene.tree;

  @override
  String toString() => 'removing';
}
