import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

/// Visit Configuration file, marked with `@localize_it`
class ModelVisitor extends SimpleElementVisitor<dynamic> {
  List<String> supportedLanguageCodes = [];
  late String baseLanguageCode;

  late String deepLAuthKey;

  late String location;

  late String mapName;

  late bool useGetX;

  late bool preferDoubleQuotes;

  // New configuration options with defaults
  int deepLDelayMs = 0;
  bool logTranslations = false;

  @override
  dynamic visitFieldElement(FieldElement element) {
    location = element.source!.fullName;

    final valueRaw = element.computeConstantValue();
    element.name;

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
  }
}
