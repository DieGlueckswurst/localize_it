/// Runtime hooks for localize_it.
class LocalizeIt {
  LocalizeIt._();

  /// Resolves a base-language key to its translation in the current locale.
  ///
  /// Defaults to returning the key unchanged. Set it once at app start, e.g.
  /// with GetX:
  /// ```dart
  /// LocalizeIt.translate = (key) => key.tr;
  /// ```
  static String Function(String key) translate = _identity;

  static String _identity(String key) => key;
}

/// Translation with named placeholders.
extension LocalizeItInterpolation on String {
  /// Translates this key via [LocalizeIt.translate] and replaces every
  /// `{name}` placeholder with the matching value from [args].
  ///
  /// ```dart
  /// 'Hallo {name}'.trWithArgs({'name': username})
  /// ```
  ///
  /// Placeholders without a matching entry in [args] are left untouched.
  String trWithArgs(Map<String, Object?> args) {
    var result = LocalizeIt.translate(this);
    args.forEach((name, value) {
      result = result.replaceAll('{$name}', '${value ?? ''}');
    });
    return result;
  }
}
