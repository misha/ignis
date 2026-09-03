// SPDX-AI-Disclosure: ai-generated

part of 'core.dart';

/// Logic that lives outside the tree and serves the nodes taking part in it.
abstract class Server {
  /// Scopes [cleanup] to the node currently building, if there is one, so a
  /// registration made in a build is remade by every build and dies with the
  /// node. Elsewhere the caller keeps it.
  ///
  /// TODO: Clarify usage and possibly rename this method.
  @protected
  Cleanup scope(Cleanup cleanup) => _trash(cleanup);
}

/// A server stepped once per tick.
///
/// Generally held by a node in the tree, which calls [process] to run it.
abstract class SteppedServer extends Server {
  void process(double dt);
}

/// A server fed events as they arrive.
///
/// Generally held wherever its scope demands (e.g. globally on `Ignis` on per
/// node in a host node).
abstract class EventServer<E> extends Server {
  bool dispatch(E event);
}
