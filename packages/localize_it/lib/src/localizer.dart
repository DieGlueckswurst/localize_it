import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:build/build.dart';
import 'package:http/http.dart' as http;

import 'package:analyzer/dart/element/element.dart';
import 'package:localize_it_annotation/localize_it_annotation.dart';
import 'package:source_gen/source_gen.dart';

import 'model_visitor.dart';

/// This is a comment to get Pub Points
class Localizer extends GeneratorForAnnotation<LocalizeItAnnotation> {
  String baseLanguageCode = '';
  List<String> supportedLanguageCodes = [];

  late bool useDeepL;
  late String deepLAuthKey;
  late bool useGetX;
  late bool preferDoubleQuotes;

  // New configuration options
  late int deepLDelayMs;
  late bool logTranslations;

  late String baseFilePath;
  late String localizationFilePath;

  int missingLocalizationsCounter = 0;
  int successfullyLocalizedCounter = 0;

  late final String escapedQuote;
  late final String missingTranslationPlaceholderText;

  /// Files (base names) each key is used in, in the order they were found.
  final Map<String, List<String>> _usages = {};

  /// Keys from `.trIn(context)`: the quoted base string and the raw context.
  final Map<String, ({String text, String context})> _contextKeys = {};

  @override
  Future<void> generateForAnnotatedElement(
    Element element,
    ConstantReader annotation,
    BuildStep buildStep,
  ) async {
    final visitor = ModelVisitor();

    // Visits all the children of element in no particular order.
    element.visitChildren(visitor);

    deepLAuthKey = visitor.deepLAuthKey;
    useDeepL = deepLAuthKey.isNotEmpty;
    useGetX = visitor.useGetX;
    preferDoubleQuotes = visitor.preferDoubleQuotes;

    // Assign new configuration options
    deepLDelayMs = visitor.deepLDelayMs;
    logTranslations = visitor.logTranslations;

    escapedQuote = preferDoubleQuotes ? '"' : '\'';
    missingTranslationPlaceholderText =
        '$escapedQuote--missing translation--$escapedQuote';

    final rawLocation = visitor.location;

    final pathForDirectory = rawLocation.substring(
      rawLocation.indexOf('lib'),
      rawLocation.lastIndexOf('/'),
    );
    const directoryName = '/localizations';

    // Make Directory with path lib/l10n/localizations
    final localizationsDirectory = Directory(pathForDirectory + directoryName);

    if (!localizationsDirectory.existsSync()) {
      await localizationsDirectory.create();
    }

    // Make Directory for Base Localization
    final baseLocalizationDir = Directory(
      '${localizationsDirectory.path}/base',
    );

    if (!baseLocalizationDir.existsSync()) {
      await baseLocalizationDir.create();
    }

    baseFilePath = baseLocalizationDir.path;
    localizationFilePath = localizationsDirectory.path;

    baseLanguageCode = visitor.baseLanguageCode;
    supportedLanguageCodes = visitor.supportedLanguageCodes;

    await translate();

    if (useGetX) {
      await _generateTranslationKeysForGetX(pathForDirectory);
    }

    return;
  }

  /// Maps [supportedLanguageCodes] to their localizations-files.
  /// `translation_keys` can simply be passed to `GetMaterialApp`
  /// to enable Localization.
  Future<void> _generateTranslationKeysForGetX(String path) async {
    const fileName = 'translation_keys.dart';
    final filePath = '$path/$fileName';
    File file = File(filePath);

    if (!file.existsSync()) {
      await file.create();
    }
    final sink = file.openWrite();
    const relativeDirectoryPathForLocalizations = 'localizations/';

    sink.writeln(
      'import \'${relativeDirectoryPathForLocalizations}base/$baseLanguageCode.g.dart\';',
    );
    for (String code in supportedLanguageCodes) {
      sink.writeln(
        'import \'$relativeDirectoryPathForLocalizations$code.g.dart\';',
      );
    }
    sink.write('\n');

    sink.writeln('const Map<String, Map<String, String>> translationsKeys = {');
    sink.writeln('\t\'$baseLanguageCode\': $baseLanguageCode,');
    for (String code in supportedLanguageCodes) {
      sink.writeln('\t\'$code\': $code,');
    }
    sink.writeln('};');

    await sink.flush();
    await sink.close();
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

    final libDir = Directory('lib');

    /// Keeps track of all the words to translate to avoid duplicates
    final allStringsToTranslate = List<String>.empty(growable: true);

    final fileNamesWithTranslation = <String, List<String>>{};

    // A quoted string cannot span lines, so `\n` is excluded from its content.
    // Line breaks are still allowed between the closing quote and `.tr`.
    // Group 1 is the quoted string, group 2 the context of `.trIn('context')`.
    final q = preferDoubleQuotes ? '"' : "'";
    final quoted = '$q[^$q\\\\\\n]*(?:\\\\.[^$q\\\\\\n]*)*$q';
    final matchTranslationExtension = RegExp(
      '($quoted)\\s*\\.(?:trIn\\s*\\(\\s*($quoted)|tr(?:WithArgs)?\\b)',
    );
    final unescapedDollar = RegExp(r'(?<!\\)\$');

    try {
      final files = await _getDirectorysContents(libDir);
      final dartFiles = _getDartFiles(files);

      await Future.forEach(dartFiles, (File fileEntity) async {
        final translationForSpecificFile = List<String>.empty(growable: true);

        final fileContent = await _readFileContent(fileEntity.path);

        final wordMatches = matchTranslationExtension.allMatches(fileContent);

        for (final wordMatch in wordMatches) {
          if (_isInCommentLine(fileContent, wordMatch.start)) continue;

          final text = wordMatch.group(1)!;
          final context = wordMatch.group(2);

          if (unescapedDollar.hasMatch(text) ||
              (context != null && unescapedDollar.hasMatch(context))) {
            stdout.writeln(
              '⚠️    Skipped ${fileEntity.path}: $text uses string '
              'interpolation. Use a {placeholder} with .trWithArgs instead.\n',
            );
            continue;
          }

          final wordCleaned = context == null
              ? text
              : _contextKey(text, context);
          if (context != null) {
            _contextKeys[wordCleaned] = (text: text, context: context);
          }

          final fileName = _basePath(fileEntity);
          final usedIn = _usages.putIfAbsent(wordCleaned, () => []);
          if (!usedIn.contains(fileName)) usedIn.add(fileName);

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
    lister.listen(
      (file) => files.add(file),
      onError: (Object error) => completer.completeError(error),
      onDone: () => completer.complete(files),
    );
    return completer.future;
  }

  /// Returns all hand-written dart files in a list of [files]. Generated files
  /// and the localization output are skipped.
  Iterable<File> _getDartFiles(List<FileSystemEntity> files) {
    // Trailing separator, so siblings like `localizations_utils.dart` still match.
    final outputDir =
        '${Directory(localizationFilePath).absolute.path}${Platform.pathSeparator}';
    return files.whereType<File>().where((file) {
      final path = file.path;
      return path.endsWith('.dart') &&
          !path.endsWith('.g.dart') &&
          !path.endsWith('.freezed.dart') &&
          !file.absolute.path.startsWith(outputDir);
    });
  }

  /// Whether the line containing [offset] is a `//` or `///` comment.
  bool _isInCommentLine(String content, int offset) {
    final lineStart = content.lastIndexOf('\n', offset) + 1;
    return content.substring(lineStart, offset).trimLeft().startsWith('//');
  }

  /// Reads, decodes and returns the content of a given [filePath]
  Future<String> _readFileContent(String filePath) async {
    final readStream = File(filePath).openRead();
    return utf8.decodeStream(readStream);
  }

  /// Joins the quoted [text] and quoted [context] of `.trIn` into one quoted
  /// key, the same way `LocalizeIt.contextKey` does at runtime:
  /// `'Einladung'` + `'Anlass'` -> `'Einladung@@Anlass'`.
  String _contextKey(String text, String context) {
    final key = LocalizeIt.contextKey(
      _removeFirstAndLastCharacter(text),
      _removeFirstAndLastCharacter(context),
    );
    return '$escapedQuote$key$escapedQuote';
  }

  /// The quoted base-language string of a [key]: the key itself, or the
  /// string without its context for `.trIn` keys.
  String _baseText(String key) => _contextKeys[key]?.text ?? key;

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
        sink.writeln('\t$translation: ${_baseText(translation)},');
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
  /// Creates a file with the [language] as a name.
  Future<void> _writeTranslationsToFile(
    File file,
    Map<String, List<String>> fileNamesWithTranslation, {
    required FutureOr<void> Function(String, IOSink) writeKeyAndValue,
    required String language,
  }) async {
    final sink = file.openWrite();

    sink.writeln('const Map<String, String> $language = {');

    // inkrementelles update von den files und nicht immer alles neuschreiben
    await Future.forEach(fileNamesWithTranslation.entries, (
      MapEntry<String, List<String>> entry,
    ) async {
      sink.writeln('\n\t//  ${entry.key}');
      await Future.forEach(entry.value, (String translation) async {
        // A key used in several files gets one translation for all of them,
        // so translators should know every place it shows up.
        final otherFiles = [
          for (final file in _usages[translation] ?? const <String>[])
            if (file != entry.key) file,
        ];
        if (otherFiles.isNotEmpty) {
          const maxListed = 5;
          final listed = otherFiles.take(maxListed).join(', ');
          final more = otherFiles.length > maxListed
              ? ' and ${otherFiles.length - maxListed} more'
              : '';
          sink.writeln('\t// also used in: $listed$more');
        }
        await writeKeyAndValue(translation, sink);
      });
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
      final file = File('$localizationFilePath/$code.g.dart');
      if (!file.existsSync()) {
        await file.create();
      }
      localizationFiles.add(file);
    }
    return localizationFiles;
  }

  Future<File> _getBaseFile() async {
    final file = File('$baseFilePath/$baseLanguageCode.g.dart');
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

    Map<String, String> oldTranslations = {};

    if (fileContent.isNotEmpty) {
      // Only whole comment lines: a translation may contain `//` (URLs).
      final matchComments = RegExp(r'^[ \t]*\/\/.*\n?', multiLine: true);
      // Remove Comments
      var keysAndValues = fileContent.replaceAll(matchComments, '');
      // Remove first line. Only the first `= {` belongs to the map declaration,
      // translations may contain the same sequence (e.g. `'Sum = {total}'`).
      const mapStart = '= {';
      keysAndValues = keysAndValues
          .substring(keysAndValues.indexOf(mapStart) + mapStart.length)
          .trim();
      // Remove last closing curly bracket
      keysAndValues.substring(0, keysAndValues.length - 1);

      final splittedKeysAndValues = keysAndValues.split(',\n');

      for (final keyAndValue in splittedKeysAndValues) {
        // Last element is empty so this check is neccessary
        if (keyAndValue.contains('$escapedQuote:')) {
          final keyAndValueSeperated = keyAndValue.split('$escapedQuote:');
          // Add single quote for key since it was removed when splitting it
          oldTranslations['${keyAndValueSeperated[0].trim()}$escapedQuote'] =
              keyAndValueSeperated[1].trim();
        }
      }
    }

    // Remove translations from file that are no longer in the project
    for (final key in [...oldTranslations.keys]) {
      if (!allTranslations.contains(key)) {
        oldTranslations.remove(key);
      }
    }

    final file = File(fileEntity.path);
    final language = _getLanguage(file);

    await _writeTranslationsToFile(
      file,
      fileNamesWithTranslation,
      language: language,
      writeKeyAndValue: (oldTranslationKey, sink) async {
        final entryExistsForTranslation = oldTranslations.containsKey(
          oldTranslationKey,
        );

        final entryExistsButIsEmpty =
            entryExistsForTranslation &&
            (oldTranslations[oldTranslationKey] ?? '').isEmpty;

        final entryExistsButIsMissingTranslation =
            oldTranslations[oldTranslationKey] ==
            missingTranslationPlaceholderText;

        final entryHasPlaceholderMismatch =
            entryExistsForTranslation &&
            !entryExistsButIsEmpty &&
            !entryExistsButIsMissingTranslation &&
            !_hasSamePlaceholders(
              _baseText(oldTranslationKey),
              oldTranslations[oldTranslationKey]!,
            );

        if (entryHasPlaceholderMismatch) {
          stdout.writeln(
            '❗️    Placeholder mismatch, resetting translation: $oldTranslationKey',
          );
        }

        final isMissing =
            !entryExistsForTranslation ||
            entryExistsButIsEmpty ||
            entryExistsButIsMissingTranslation ||
            entryHasPlaceholderMismatch;

        if (isMissing && !useDeepL) {
          missingLocalizationsCounter++;
        }

        var value = isMissing
            ? useDeepL
                  ? await _deepLTranslate(
                      _removeFirstAndLastCharacter(
                        _baseText(oldTranslationKey),
                      ),
                      language,
                      context: switch (_contextKeys[oldTranslationKey]) {
                        final key? => _removeFirstAndLastCharacter(key.context),
                        null => null,
                      },
                    )
                  : missingTranslationPlaceholderText
            : oldTranslations[oldTranslationKey] ?? '';

        sink.writeln("\t$oldTranslationKey: $value,");
      },
    );
    stdout.writeln('💡    Missing Localizations: $missingLocalizationsCounter');
    if (missingLocalizationsCounter > 0) {
      stdout.writeln(
        '      Marked with $missingTranslationPlaceholderText, fill them in manually or with an AI agent.',
      );
    }
    if (useDeepL) {
      stdout.writeln(
        '💡    New Localizations:     $successfullyLocalizedCounter\n',
      );
    }
    stdout.writeln('✅    Done!\n\n');
  }

  /// Helper function used to get the raw String without
  /// leading and trailing quote
  String _removeFirstAndLastCharacter(String string) {
    return string.substring(1, string.length - 1);
  }

  /// Returns the translation for the given [text] and the [language] in which it should be translated
  /// via the DeepL API
  Future<String> _deepLTranslate(
    String text,
    String language, {
    String? context,
  }) async {
    try {
      // Only show translation request if configured to do so
      if (logTranslations) {
        stdout.writeln('Translating text: \n$text\n to $language');
      }

      final url = Uri.https('api-free.deepl.com', '/v2/translate');

      // Protect `{name}` placeholders from being translated by sending them
      // as ignored XML tags.
      final hasPlaceholders = _placeholderPattern.hasMatch(text);

      final body = <String, dynamic>{
        'text': hasPlaceholders ? _placeholdersToXml(text) : text,
        'target_lang': language,
        'source_lang': baseLanguageCode.toUpperCase(),
        // Steers word choice, is not translated itself.
        'context': ?context,
        if (hasPlaceholders) 'tag_handling': 'xml',
        if (hasPlaceholders) 'ignore_tags': 'ph',
      };

      final headers = <String, String>{
        'Authorization': 'DeepL-Auth-Key $deepLAuthKey',
        'Content-Type': 'application/x-www-form-urlencoded',
      };

      final response = await http.post(url, body: body, headers: headers);

      // Add delay after the request if configured
      if (deepLDelayMs > 0) {
        await Future.delayed(Duration(milliseconds: deepLDelayMs));
      }

      if (response.statusCode != 200) {
        stdout.writeln(
          '❗️   Something went wrong while translating with DeepL...',
        );
        stdout.writeln('❗️   Status Code: ${response.statusCode}');
        missingLocalizationsCounter++;
        return missingTranslationPlaceholderText;
      }

      final json =
          jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>?;

      if (json != null) {
        var translated = json['translations'][0]['text'] as String;

        if (hasPlaceholders) {
          translated = _placeholdersFromXml(translated);
        }

        if (!_hasSamePlaceholders(text, translated)) {
          stdout.writeln('❗️   DeepL changed the placeholders of: $text');
          missingLocalizationsCounter++;
          return missingTranslationPlaceholderText;
        }

        successfullyLocalizedCounter++;

        text = _escapeSingleQuotes(translated);
        // Remove double escape characters
        text = text.replaceAll("\\\\'", "\\'");

        return '$escapedQuote$text$escapedQuote';
      }

      missingLocalizationsCounter++;

      return missingTranslationPlaceholderText;
    } on Exception {
      stderr.writeln(
        '❗️    Something went wrong while translating with DeepL.',
      );
      stderr.writeln('❗️    Make sure that you are connected to the Internet.');
      return missingTranslationPlaceholderText;
    }
  }

  /// Matches `{name}` placeholders used with `.trWithArgs`.
  static final _placeholderPattern = RegExp(r'\{(\w+)\}');

  /// Whether [a] and [b] contain exactly the same set of `{name}` placeholders.
  bool _hasSamePlaceholders(String a, String b) {
    Set<String> placeholders(String s) =>
        _placeholderPattern.allMatches(s).map((m) => m.group(1)!).toSet();
    final first = placeholders(a);
    final second = placeholders(b);
    return first.length == second.length && first.containsAll(second);
  }

  String _placeholdersToXml(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAllMapped(_placeholderPattern, (m) => '<ph>${m.group(1)}</ph>');

  String _placeholdersFromXml(String text) => text
      .replaceAllMapped(RegExp(r'<ph>(\w+)</ph>'), (m) => '{${m.group(1)}}')
      .replaceAll('&lt;', '<')
      .replaceAll('&gt;', '>')
      .replaceAll('&amp;', '&');

  /// Makes sure to skip single-quotes in actual Strings.
  /// Escpecially common for English (e.g. "I'm Christian.").
  String _escapeSingleQuotes(String word) {
    return word.replaceAll('\'', '\\\'');
  }
}
