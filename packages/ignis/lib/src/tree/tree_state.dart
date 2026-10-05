part of 'tree.dart';

sealed class TreeState<T extends Tree<T>> {
  const TreeState();

  T? get parent => null;

  bool get isMounted => false;
}

final class Detached<T extends Tree<T>> extends TreeState<T> {
  const Detached._();

  @override
  String toString() => 'detached';
}

final class Attached<T extends Tree<T>> extends TreeState<T> {
  @override
  final T parent;

  const Attached._(this.parent);

  @override
  String toString() => 'attached';
}

final class Arriving<T extends Tree<T>> extends TreeState<T> {
  final T target;

  const Arriving._(this.target);

  @override
  String toString() => 'arriving';
}

final class Root<T extends Tree<T>> extends TreeState<T> {
  const Root._();

  @override
  bool get isMounted => true;

  @override
  String toString() => 'root';
}

final class Mounted<T extends Tree<T>> extends TreeState<T> {
  @override
  final T parent;

  const Mounted._(this.parent);

  @override
  bool get isMounted => true;

  @override
  String toString() => 'mounted';
}

final class Moving<T extends Tree<T>> extends TreeState<T> {
  final T from;
  final T target;

  const Moving._(this.from, this.target);

  @override
  bool get isMounted => true;

  @override
  T get parent => from;

  @override
  String toString() => 'moving';
}

final class Removing<T extends Tree<T>> extends TreeState<T> {
  @override
  final T parent;

  const Removing._(this.parent);

  @override
  bool get isMounted => true;

  @override
  String toString() => 'removing';
}
