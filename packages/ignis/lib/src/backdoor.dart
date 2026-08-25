part of 'core.dart';

// Backdoors: reaches into core internals when a subsystem requires it.

/// Hands [cleanup] to the node currently building, if there is one.
///
/// A subscription or a claim made inside a [Node.build] belongs to that node:
/// the cleanup goes to its [Node.trash], so it is remade by every build and
/// dies with the node, and the caller is handed a no-op. Everywhere else the
/// caller owns the cleanup, and gets it straight back.
Cleanup _trash(Cleanup cleanup) {
  final builder = Node._builder;
  if (builder == null) return cleanup;
  builder.trash(cleanup);
  return _noop;
}

void _noop() {
  // Nothing to do.
}
