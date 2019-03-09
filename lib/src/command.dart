class Command {
  const Command._(this.value);

  final int value;

  /// MoveTo: 1. (2 parameters follow)
  static const Command MoveTo = Command._(1);

  /// LineTo: 2. (2 parameters follow)
  static const Command LineTo = Command._(2);

  /// ClosePath: 7. (no parameters follow)
  static const Command ClosePath = Command._(7);
}

abstract class Filter {
  const Filter._();

  factory Filter.all() => const _All();

  factory Filter.single(String layerName) => _Single(layerName);

  factory Filter.any(Set<String> layerNames) => _Any(layerNames);

  bool include(String layerName);
}

class _All extends Filter {
  const _All() : super._();

  @override
  bool include(String layerName) => true;
}

/// A filter that only lets a single named layer be decoded.
class _Single extends Filter {
  const _Single(this.layerName) : super._();

  final String layerName;

  @override
  bool include(String layerName) => this.layerName == layerName;
}

/// A filter that only allows the named layers to be decoded.
class _Any extends Filter {
  const _Any(this.layerNames) : super._();

  final Set<String> layerNames;

  @override
  bool include(String layerName) {
    return layerNames.contains(layerName);
  }
}
