import 'package:flutter/widgets.dart';

import 'demos/sprites.dart';

/// Every demo scene on the site, by the name its `<Demo/>` slot carries.
final Map<String, Widget Function()> _demos = {
  ...spriteDemos,
};

/// The scene one `<Demo name="..."/>` slot resolves to.
class DemoView extends StatelessWidget {
  final String name;

  const DemoView({
    required this.name,
    super.key,
  });

  @override
  Widget build(context) {
    final demo = _demos[name];

    if (demo == null) {
      throw ArgumentError.value(name, 'name', 'No demo by that name.');
    }

    return demo();
  }
}
