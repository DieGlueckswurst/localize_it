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

  /// Joins a string and its context into one key, see [LocalizeItContext.trIn].
  static const String contextSeparator = '@@';

  /// The key localize_it generates for [text] marked with `.trIn(context)`.
  static String contextKey(String text, String context) =>
      '$text$contextSeparator$context';

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
  String trWithArgs(Map<String, Object?> args) =>
      _interpolate(LocalizeIt.translate(this), args);
}

/// Translation of a string that needs a different wording in some languages
/// depending on where it is shown.
extension LocalizeItContext on String {
  /// Translates this string in the given [context].
  ///
  /// The same base string can mean different things on different screens.
  /// German `'Einladung'` is the title of an invite screen and also an
  /// occasion tag ("having guests over"), which English needs as two different
  /// words. `.trIn` gives each place its own key, so each can get its own
  /// translation, while the base language still shows the plain string:
  ///
  /// ```dart
  /// 'Einladung'.tr                  // "Invitation"
  /// 'Einladung'.trIn('Anlass')      // "Having guests"
  /// 'Hallo {name}'.trIn('Push', {'name': username})
  /// ```
  ///
  /// [context] must be a string literal, like the string itself, so
  /// localize_it can find it. It is also passed to DeepL as context.
  /// `{name}` placeholders are replaced with the values from [args].
  String trIn(String context, [Map<String, Object?> args = const {}]) {
    final key = LocalizeIt.contextKey(this, context);
    final translated = LocalizeIt.translate(key);
    // Not generated yet: show the plain string, never the internal key.
    final text = translated == key ? this : translated;
    return _interpolate(text, args);
  }
}

String _interpolate(String text, Map<String, Object?> args) {
  var result = text;
  args.forEach((name, value) {
    result = result.replaceAll('{$name}', '${value ?? ''}');
  });
  return result;
}
