import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:ignis/ignis.dart';

/// Calls [handle] whenever [signal] is emitted.
void useSignal0(Signal0 signal, void Function() handle) {
  useEffect(() {
    return signal(handle);
  }, [signal, handle]);
}

/// Calls [handle] whenever [signal] is emitted.
void useSignal1<A>(Signal1<A> signal, void Function(A) handle) {
  useEffect(() {
    return signal(handle);
  }, [signal, handle]);
}

/// Calls [handle] whenever [signal] is emitted.
void useSignal2<A, B>(Signal2<A, B> signal, void Function(A, B) handle) {
  useEffect(() {
    return signal(handle);
  }, [signal, handle]);
}

/// Calls [handle] whenever [signal] is emitted.
void useSignal3<A, B, C>(Signal3<A, B, C> signal, void Function(A, B, C) handle) {
  useEffect(() {
    return signal(handle);
  }, [signal, handle]);
}
