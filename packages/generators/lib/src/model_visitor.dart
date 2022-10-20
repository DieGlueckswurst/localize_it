import 'package:analyzer/dart/element/visitor.dart';
import 'package:analyzer/dart/element/element.dart';

class ModelVisitor extends SimpleElementVisitor<dynamic> {
  String className;

  Map<dynamic, dynamic> fields = <dynamic, dynamic>{};

  List<String> supportedLanguageCodes;
  String baseLanguage;

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
    final type = element.type.toString().replaceAll('*', '');

    final valueRaw = element.computeConstantValue();

    if (valueRaw.toStringValue() != null) {
      fields[type] = valueRaw.toStringValue();
    }
    if (valueRaw.toListValue() != null) {
      fields[type] = valueRaw.toListValue();
    }

    fields[type] = valueRaw;
  }

  // @override
  // dynamic visitLabelElement(LabelElement element) {
  //   labelName = element.name;
  //   // return super.visitLabelElement(element);
  // }
}
