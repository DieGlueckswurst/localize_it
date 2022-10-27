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
  /// Supports all the currently available `target_lang`
  /// on [DeepL](https://www.deepl.com/de/docs-api/translate-text/translate-text/).
  ///
  /// Defaults to: `['en' (English), 'es' (Spanish)]`
  static const List<String> supportedLanguageCodes = [
    'en',
    'es',
  ];

  /// Providing a `deepLAuthKey` enables translation generation
  /// via the [DeepL API](https://www.deepl.com/de/pro-api?cta=header-pro-api/).
  /// If no key is provided (empty String), all *marked Strings* (end with `.tr`) in your project
  /// will get translated to `'--missing translation--'.`
  static const String deepLAuthKey = '5bcb1202-12d5-2e63-f8ca-b087c47cad1b:fx';

  /// Enabling `useGetX` generates `Map<String, Map<String,String>> translationKeys` which can
  /// simply be passed to `GetMaterialApp`.
  static const bool useGetX = true;
}
