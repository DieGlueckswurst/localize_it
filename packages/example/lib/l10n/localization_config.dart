import 'package:localize_it_annotation/localize_it_annotation.dart';

@localize_it
class LocaleConfiguration {
  /// Expects a lanugage code in **lowercase**.
  ///
  /// Supports all the currently available `source_lang`
  /// on [DeepL](https://www.deepl.com/de/docs-api/translate-text/translate-text/).
  ///
  /// Defaults to: 'de' (German)
  static const String baseLanguageCode = 'de';

  /// Expects language codes in **lowercase**.
  /// Should *not* contain `baseLanguageCode`.
  ///
  /// Supports all the currently available `target-lang`
  /// on [DeepL](https://www.deepl.com/de/docs-api/translate-text/translate-text/)
  ///
  /// Example for an App that supports English and Spanish:
  ///
  ///   ```
  ///   static const List<String> supportedLanguageCodes = [
  ///     'en',
  ///     'es',
  ///   ];
  ///
  ///   ```
  ///
  /// Defaults to: `['en' (English), 'es' (Spanish)]`
  static const List<String> supportedLanguageCodes = [
    'en',
    'es',
  ];

  /// Providing a `deepLAuthKey` enables translation generation
  /// via the [DeepL API](https://www.deepl.com/de/pro-api?cta=header-pro-api/).
  /// If no key is provided, all *marked Strings* (end with `.tr`) in your project
  /// will get translated to `'--missing translation--'`.
  static const String deepLAuthKey = '';
}
