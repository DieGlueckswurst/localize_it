import 'package:analyzer/dart/constant/value.dart';
import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

class ModelVisitor extends SimpleElementVisitor<dynamic> {
  String className;

  // Map<dynamic, dynamic> fields = <dynamic, dynamic>{};

  List<String> supportedLanguageCodes = [];
  String baseLanguageCode;

  String location;
  dynamic dynamicLocation;

  String mapName;

  @override
  dynamic visitConstructorElement(ConstructorElement element) {
    final elementReturnType = element.type.returnType.toString();

    // DartType ends with '*', which needs to be eliminated
    // for the generated code to be accurate.

    className = elementReturnType.replaceFirst('*', '');
  }

  @override
  dynamic visitLibraryElement(LibraryElement element) {
    return super.visitLibraryElement(element);
  }

  @override
  dynamic visitFieldElement(FieldElement element) {
    location = element.source.fullName;

    final valueRaw = element.computeConstantValue();

    if (valueRaw.toStringValue() != null) {
      baseLanguageCode = valueRaw.toStringValue();
    } else if (valueRaw.toListValue() != null) {
      final list = valueRaw.toListValue();

      for (final object in list) {
        supportedLanguageCodes.add(object.toStringValue());
      }
    }
  }
}
