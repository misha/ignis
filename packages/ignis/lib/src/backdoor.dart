// SPDX-AI-Disclosure: none
part of 'core.dart';

// Backdoors: reaches into core internals when a subsystem requires it.

/// The node currently running its [Node.build], if there is one.
@internal
Node? get building => Node._building;

/// Hands [cleanup] to the node currently building, if there is one.
///
/// A subscription or a claim made inside a [Node.build] belongs to that node:
/// the cleanup goes to its [Node.trash], so it is remade by every build and
/// dies with the node, and the caller is handed a no-op. Everywhere else the
/// caller owns the cleanup, and gets it straight back.
@internal
Cleanup scope(Cleanup cleanup) {
  final node = building;
  if (node == null) return cleanup;
  node.trash(cleanup);
  return _noop;
}

void _noop() {
  // Nothing to do.
}
