import 'dart:io';

import 'package:build/src/builder/build_step.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:localize_it_annotation/localize_it_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'model_visitor.dart';

class TranslationGenerator
    extends GeneratorForAnnotation<LocalizeItAnnotation> {
  String test = 'Hallo';

  @override
  Future<String> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final visitor = ModelVisitor();

    // Visits all the children of element in no particular order.
    element.visitChildren(
      visitor,
    );

    stdout.writeln(visitor.location);

    const directoryName = '/localizations';

    final rawLocation = visitor.location;

    final pathForDirectory = rawLocation.substring(
      rawLocation.indexOf(
        'lib',
      ),
      rawLocation.lastIndexOf('/'),
    );

    // Make Directory with path lib/l10n/localizations
    final localizationsDirectory = await Directory(
      pathForDirectory + directoryName,
    ).create();

    // Make Directory for Base Localization
    final baseLocalizationDir = await Directory(
      localizationsDirectory.path + '/base',
    ).create();

    final baseLanguageCode = visitor.baseLanguageCode;
    final baseFile = await File(
      '${baseLocalizationDir.path}/$baseLanguageCode.g.dart',
    ).create();
    final sink = baseFile.openWrite();
    sink.writeln('// Base: $baseLanguageCode');

    await sink.flush();
    await sink.close();

    for (final code in visitor.supportedLanguageCodes) {
      final file =
          await File('${localizationsDirectory.path}/$code.g.dart').create();

      final sink = file.openWrite();

      sink.writeln('// Language: $code');

      await sink.flush();
      await sink.close();
    }

    return null;
  }
}
