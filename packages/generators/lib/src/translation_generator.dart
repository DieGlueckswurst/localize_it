import 'dart:io';

import 'package:build/src/builder/build_step.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:source_gen/source_gen.dart';

import 'package:annotations/annotations.dart';

import 'model_visitor.dart';

class TranslationGenerator extends GeneratorForAnnotation<LocalizedAnnotation> {
  String test = 'Hallo';
  // 1
  @override
  String generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) {
    // 2
    final visitor = ModelVisitor();
    element.visitChildren(
      visitor,
    ); // Visits all the children of element in no particular order.

    // 4
    final classBuffer = StringBuffer();
    classBuffer.writeln('/*');
    // classBuffer.writeln('base language: ' + visitor.baseLanguage);

    // stdout.writeln('✅' * 10);

    const List<String> codes = ['de', 'us', 'es'];

    for (final code in codes) {
      File('lib/translations/$code.dart').create(recursive: true);
    }

    // classBuffer.writeln(visitor.fields.entries);

    // // 5
    // classBuffer.writeln('class $className extends ${visitor.className} {');

    // // 6
    // classBuffer.writeln('Map<String, dynamic> variables = {};');

    // // 7
    // classBuffer.writeln('$className() {');

    for (final key in visitor.fields.keys) {
      // ignore: lines_longer_than_80_chars
      classBuffer
          .writeln('type: ${key}' + ', value: ' + '${visitor.fields[key]}');
    }

    // classBuffer.writeln('supported language codes: ');

    // 8
    // for (final languageCode in visitor.supportedLanguageCodes) {
    //   classBuffer.writeln(languageCode);
    // }

    // // 9
    // classBuffer.writeln('}');

    // // 10
    // generateGettersAndSetters(visitor, classBuffer);

    // // 11
    // classBuffer.writeln('}');

    // 12
    classBuffer.writeln('*/');

    return null;
  }
}
