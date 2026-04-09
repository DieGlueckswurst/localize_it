import 'package:analyzer/dart/element/element.dart';
import 'package:analyzer/dart/element/visitor2.dart';

/// Visit Configuration file, marked with `@localize_it`
class ModelVisitor extends SimpleElementVisitor2<Object?> {
  List<String> supportedLanguageCodes = [];
  late String baseLanguageCode;

  String deepLAuthKey = '';

  late String location;

  late String mapName;

  bool useGetX = false;

  /// Default matches single-quote `.tr` scanning when omitted from config.
  bool preferDoubleQuotes = false;

  // New configuration options with defaults
  int deepLDelayMs = 0;
  bool logTranslations = false;

  @override
  Object? visitFieldElement(FieldElement element) {
    location = element.firstFragment.libraryFragment.source.fullName;

    final valueRaw = element.computeConstantValue();

    if (valueRaw?.toStringValue() != null) {
      if (element.name == 'baseLanguageCode') {
        baseLanguageCode = valueRaw!.toStringValue()!;
      } else if (element.name == 'deepLAuthKey') {
        deepLAuthKey = valueRaw!.toStringValue()!;
      }
    } else if (valueRaw?.toListValue() != null) {
      final list = valueRaw?.toListValue();

      for (final object in list!) {
        supportedLanguageCodes.add(object.toStringValue()!);
      }
    } else if (valueRaw?.toBoolValue() != null) {
      if (element.name == 'useGetX') {
        useGetX = valueRaw!.toBoolValue()!;
      } else if (element.name == 'preferDoubleQuotes') {
        preferDoubleQuotes = valueRaw!.toBoolValue()!;
      } else if (element.name == 'logTranslations') {
        logTranslations = valueRaw!.toBoolValue()!;
      }
    } else if (valueRaw?.toIntValue() != null) {
      if (element.name == 'deepLDelayMs') {
        deepLDelayMs = valueRaw!.toIntValue()!;
      }
    }
    return null;
  }
}
