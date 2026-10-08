import 'package:flutter/foundation.dart';
import 'package:ignis/src/address.dart';
import 'package:ignis/src/cow.dart';
import 'package:ignis/src/message.dart';

/// Posts messages to every subscribed [Address], in subscription order.
///
/// Subscribing or unsubscribing while a mail is out takes effect the next mail.
mixin Mailer {
  final _subscribers = Cow<Address>();

  /// Starts posting this mailer's messages to [address].
  void subscribe(Address address) => _subscribers.add(address);

  /// Stops posting this mailer's messages to [address].
  void unsubscribe(Address address) => _subscribers.remove(address);

  /// Posts [message] to every subscriber.
  @protected
  void mail(Message message) {
    for (final subscriber in _subscribers) {
      subscriber.post(message);
    }
  }
}
