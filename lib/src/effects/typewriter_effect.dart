import 'package:ignis/src/effects/controlled_effect.dart';
import 'package:ignis/src/nodes/text_node.dart';
import 'package:ignis/src/signal.dart';

/// An effect that animates a [TextNode]'s text by typing [to], starting
/// from [from] already having been typed.
class TypewriterEffect extends ControlledEffect {
  TextNode? _target;
  final String _to;
  final int _from;
  final int _delta;
  int _typed;

  /// The node whose text is mutated by this effect.
  TextNode? get target => _target;

  /// Emitted once per character typed.
  final onType = Signal0();

  /// Types [target]'s text from [from] to [to]. [to] must start with [from].
  ///
  /// If [target] is null, resolves to the closest [TextNode].
  TypewriterEffect({
    this._target,
    String from = '',
    required String to,
    required super.controller,
    super.cleanup,
  }) : assert(to.startsWith(from), 'to must start with from.'),
       _to = to,
       _from = from.length,
       _delta = to.length - from.length,
       _typed = from.length {
    if (_target == null) {
      onMount(() {
        _target = ancestors.whereType<TextNode>().firstOrNull;
        assert(_target != null, 'Target must be set, or have a TextNode ancestor.');
      });

      onUnmount(() {
        _target = null;
      });
    }

    onProgress((progress) {
      final chars = _from + (_delta * progress).round();

      for (var i = _typed; i < chars; i += 1) {
        onType.emit();
      }

      _typed = chars;
      _target!.text = _to.substring(0, chars);
    });
  }
}
