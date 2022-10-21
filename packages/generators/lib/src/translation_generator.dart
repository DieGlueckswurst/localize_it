import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import 'package:build/src/builder/build_step.dart';
import 'package:analyzer/dart/element/element.dart';
import 'package:localize_it_annotation/localize_it_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'model_visitor.dart';

class TranslationGenerator
    extends GeneratorForAnnotation<LocalizeItAnnotation> {
  String baseLanguageCode = '';
  List<String> supportedLanguageCodes = [];

  bool useDeepL = true;

  late String baseFilePath;
  late String localizationFilePath;

  int missingLocalizationsCounter = 0;
  int successfullyLocalizedCounter = 0;

  @override
  Future<void> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final visitor = ModelVisitor();

    // Visits all the children of element in no particular order.
    element.visitChildren(
      visitor,
    );

    final rawLocation = visitor.location;

    final pathForDirectory = rawLocation.substring(
      rawLocation.indexOf(
        'lib',
      ),
      rawLocation.lastIndexOf('/'),
    );
    const directoryName = '/localizations';

    // Make Directory with path lib/l10n/localizations
    final localizationsDirectory = Directory(
      pathForDirectory + directoryName,
    );

    if (!localizationsDirectory.existsSync()) {
      await localizationsDirectory.create();
    }

    // Make Directory for Base Localization
    final baseLocalizationDir = Directory(
      localizationsDirectory.path + '/base',
    );

    if (!baseLocalizationDir.existsSync()) {
      await baseLocalizationDir.create();
    }

    baseFilePath = baseLocalizationDir.path;
    localizationFilePath = localizationsDirectory.path;

    baseLanguageCode = visitor.baseLanguageCode;
    supportedLanguageCodes = visitor.supportedLanguageCodes;

    await translate();

    return;
  }

  Future<void> translate() async {
    final fileNamesWithTranslation = await _getFileNamesWithTranslations();
    await _writeTranslationsToBaseFile(fileNamesWithTranslation);

    final allTranslations = <String>[];

    for (final value in fileNamesWithTranslation.values) {
      allTranslations.addAll(value);
    }

    await _writeTranslationsToAllTranslationFiles(
      allTranslations,
      fileNamesWithTranslation,
    );
  }

  /// Searching for all Strings in the project that use the `.tr` extension.
  ///
  /// Returns a map where the key is the file in which the translation were found
  /// and the values are all translation for that specific file.
  /// ```dart
  /// {
  ///   'example.dart': ["'Hello'", "'World'"],
  /// }
  /// ```
  Future<Map<String, List<String>>> _getFileNamesWithTranslations() async {
    stdout.writeln('\n');

    stdout.writeln('Getting all Strings to localize...\n');

    final currentDir = Directory.current;

    /// Keeps track of all the words to translate to avoid duplicates
    final allStringsToTranslate = List<String>.empty(growable: true);

    final fileNamesWithTranslation = <String, List<String>>{};

    try {
      final files = await _getDirectorysContents(currentDir);
      final dartFiles = _getDartFiles(files);

      await Future.forEach(dartFiles, (File fileEntity) async {
        final translationForSpecificFile = List<String>.empty(growable: true);

        final fileContent = await _readFileContent(fileEntity.path);

        final matchTranslationExtension =
            RegExp(r"('[^'\\]*(?:\\.[^'\\]*)*'\s*\.tr\b)");
        final wordMatches = matchTranslationExtension.allMatches(fileContent);

        for (final wordMatch in wordMatches) {
          final word = wordMatch.group(0)!;

          final wordCleaned = _cleanWord(word);
          if (!allStringsToTranslate.contains(wordCleaned)) {
            allStringsToTranslate.add(wordCleaned);
            translationForSpecificFile.add(wordCleaned);
          }
        }

        if (translationForSpecificFile.isNotEmpty) {
          final fileName = _basePath(fileEntity);
          fileNamesWithTranslation[fileName] = translationForSpecificFile;
        }
      });

      stdout.writeln('✅    Done!\n\n');
      return fileNamesWithTranslation;
    } catch (exception) {
      stdout.writeln('❌    Something went wrong while localizing. \n');
      stdout.writeln('      Error: $exception\n\n');
      return fileNamesWithTranslation;
    }
  }

  /// Returns all files and directorys of a given [directory].
  Future<List<FileSystemEntity>> _getDirectorysContents(Directory directory) {
    final files = <FileSystemEntity>[];
    final completer = Completer<List<FileSystemEntity>>();
    final lister = directory.list(recursive: true);
    lister.listen((file) => files.add(file),
        onError: (Object error) => completer.completeError(error),
        onDone: () => completer.complete(files));
    return completer.future;
  }

  /// Returns an iterable of all dart files in a list of [files].
  Iterable<File> _getDartFiles(List<FileSystemEntity> files) =>
      files.whereType<File>().where(
            (file) => file.path.endsWith('.dart'),
          );

  /// Reads, decodes and returns the content of a given [filePath]
  Future<String> _readFileContent(String filePath) async {
    final readStream = File(filePath).openRead();
    return utf8.decodeStream(readStream);
  }

  /// Removes the trailing `.tr` but more importantly removes whitespaces
  /// between the String and `.tr`
  /// Example:
  /// Text(
  ///   'This is a very long String. It goes on and on and on and on'
  ///    .tr,
  /// )
  String _cleanWord(String word) =>
      word.substring(0, word.lastIndexOf('\'') + 1);

  String _basePath(FileSystemEntity fileEntity) =>
      fileEntity.uri.pathSegments.last;

  /// Writes all found Strings with the `tr` exentsion [fileNamesWithTranslation] into the base translation file.
  Future<void> _writeTranslationsToBaseFile(
    Map<String, List<String>> fileNamesWithTranslation,
  ) async {
    stdout.writeln('Updating base localization file...\n');

    await _writeTranslationsToFile(
      await _getBaseFile(),
      fileNamesWithTranslation,
      language: baseLanguageCode,
      writeKeyAndValue: (translation, sink) {
        sink.writeln('\t$translation: $translation,');
      },
    );

    stdout.writeln('✅    Done!\n\n');
  }

  /// Helper function to get the language of a given localization [file]
  ///
  /// The file should have the format `{languageCode}.dart`
  String _getLanguage(FileSystemEntity file) => _basePath(file).split('.')[0];

  /// Function which writes the translations to the given [file]
  ///
  /// Needs the [fileNameWithTranslation] because based on that, the content of the [file]
  /// gets ordered.
  /// [writeKeyAndValue] is a callback function for a custom implementation on how to write
  /// the key and value of [fileNameWithTranslation].
  /// You should not flush the IOSink that get's passed to [writeKeyAndValue], because that happens at the end of this function.
  /// Creates a file with the [language] as a name
  Future<void> _writeTranslationsToFile(
    File file,
    Map<String, List<String>> fileNamesWithTranslation, {
    required void Function(String, IOSink) writeKeyAndValue,
    required String language,
  }) async {
    final sink = file.openWrite();

    sink.writeln('final Map<String, String> $language = {');

    // inkrementelles update von den files und nicht immer alles neuschreiben
    await Future.forEach(fileNamesWithTranslation.entries, (
      MapEntry<String, List<String>> entry,
    ) async {
      sink.writeln('\n\t//  ${entry.key}');
      await Future.forEach(
        entry.value,
        (String translation) => writeKeyAndValue(translation, sink),
      );
    });

    sink.writeln('};');

    await sink.flush();
    await sink.close();
  }

  /// Gets all Localization Files based on `supportedLanguageCodes`.
  /// Creates File if it does not exist.
  Future<List<File>> _getLocalizationFiles() async {
    final localizationFiles = <File>[];
    for (final code in supportedLanguageCodes) {
      final file = File(
        localizationFilePath + '/$code.g.dart',
      );
      if (!file.existsSync()) {
        await file.create();
      }
      localizationFiles.add(file);
    }
    return localizationFiles;
  }

  Future<File> _getBaseFile() async {
    final file = File(
      baseFilePath + '/$baseLanguageCode.g.dart',
    );
    if (!file.existsSync()) {
      await file.create();
    }
    return file;
  }

  /// Gets all language files in the `lib/locale/translations` path and updates the files
  /// incrementally with [allTranslations] and [fileNamesWithTranslation]
  Future<void> _writeTranslationsToAllTranslationFiles(
    List<String> allTranslations,
    Map<String, List<String>> fileNamesWithTranslation,
  ) async {
    final localizationFiles = await _getLocalizationFiles();

    // final filteredFiles = translationFiles
    //     .whereType<File>()
    //     .where((file) => !file.path.contains('/base'));

    await Future.forEach(localizationFiles, (File file) async {
      await _updateTranslations(
        file,
        allTranslations,
        fileNamesWithTranslation,
      );
    });

    stdout.writeln('\n🍻🍻🍻 Successfully updated localizations! 🍻🍻🍻\n\n\n');
  }

  /// Updates each translation file and keeps track of all
  /// missing translations, or updates missing translations with the DeepL API
  Future<void> _updateTranslations(
    FileSystemEntity fileEntity,
    List<String> allTranslations,
    Map<String, List<String>> fileNamesWithTranslation,
  ) async {
    // Reset counter for each file
    successfullyLocalizedCounter = 0;
    missingLocalizationsCounter = 0;

    stdout.writeln('Update localizations in ${_basePath(fileEntity)} ...\n');

    final fileContent = await _readFileContent(fileEntity.path);
    final matchComments = RegExp(r'\/\/.*\n?');
    final keysAndValues = fileContent.replaceAll(matchComments, '');

    Map<String, dynamic> oldTranslations;

    try {
      final json = keysAndValues.split('=')[1].replaceAll(r"'", '"').trim();
      final indexOfLastComma = json.lastIndexOf(',');
      final validJson = json
          .replaceFirst(',', '', indexOfLastComma - 1)
          .substring(0, json.length - 2);

      oldTranslations = jsonDecode(validJson) as Map<String, dynamic>;
    } catch (exception) {
      // if json is invalid oldTranslations are empty
      final message = exception is RangeError
          ? '💡    Localization file was empty or had an invalid format.\n    Generating from scratch...'
          : '💡    Something went wrong. \n    Generating from scratch...';
      stdout.writeln(message);

      oldTranslations = <String, dynamic>{};
    }

    for (final key in [...oldTranslations.keys]) {
      if (!allTranslations.contains("'$key'")) {
        oldTranslations.remove(key);
      }
    }

    const missingTranslation = '--missing translation--';

    final file = File(fileEntity.path);
    final language = _getLanguage(file);

    await _writeTranslationsToFile(
      file,
      fileNamesWithTranslation,
      language: language,
      writeKeyAndValue: (translation, sink) async {
        final oldTranslationKey = translation.replaceAll("'", '');
        final isMissing = !oldTranslations.containsKey(oldTranslationKey) ||
            oldTranslations.containsKey(oldTranslationKey) &&
                (oldTranslations[oldTranslationKey] as String? ?? '').isEmpty ||
            oldTranslations[oldTranslationKey] == missingTranslation;

        if (isMissing && !useDeepL) missingLocalizationsCounter++;

        final value = isMissing
            ? useDeepL
                ? await _deepLTranslate(oldTranslationKey, language)
                : missingTranslation
            : oldTranslations[oldTranslationKey] as String? ?? '';

        sink.writeln("\t$translation: '$value'" + ',');
      },
    );
    stdout.writeln(
      '💡    Localizations missing: $missingLocalizationsCounter',
    );
    if (useDeepL) {
      stdout.writeln(
        '💡    New Localizations:   $successfullyLocalizedCounter\n',
      );
    }
    stdout.writeln('✅    Done!\n\n');
  }

  /// Returns the translation for the given [text] and the [language] in which it should be translated
  /// via the DeepL API
  Future<String> _deepLTranslate(String text, String language) async {
    const missingTranslation = '--missing translation--';
    try {
      final url = Uri.https('api-free.deepl.com', '/v2/translate');

      final body = <String, dynamic>{
        'auth_key': '5bcb1202-12d5-2e63-f8ca-b087c47cad1b:fx',
        'text': text,
        'target_lang': language,
        'source_lang': baseLanguageCode.toUpperCase(),
      };

      final response = await http.post(url, body: body);

      if (response.statusCode != 200) {
        stdout.writeln(
          '❗️   Something went wrong while translating with DeepL. Maybe check if you provided a valid language code.',
        );
        missingLocalizationsCounter++;
        return missingTranslation;
      }

      final json = jsonDecode(
        utf8.decode(response.bodyBytes),
      ) as Map<String, dynamic>?;

      if (json != null) {
        successfullyLocalizedCounter++;

        return json['translations'][0]['text'] as String;
      }

      missingLocalizationsCounter++;

      return missingTranslation;
    } on Exception {
      stderr
          .writeln('❗️    Something went wrong while translating with deepl ');
      return missingTranslation;
    }
  }
}
