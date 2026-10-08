import 'package:ignis/src/message.dart';

/// Something a [Message] can be posted to.
mixin Address {
  /// Delivers [message] to this address.
  void post(Message message);
}
