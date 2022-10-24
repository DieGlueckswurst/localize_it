
const vscode = require('vscode');
const fs = require('fs');
const path = require('node:path');

/**
 * @param {vscode.ExtensionContext} context
 */
function activate(context) {

	// Add '...args' to get access to the clicked file/directory 
	let disposable = vscode.commands.registerCommand('localize_it.create', function (...args) {

		// Display a message box to the user
		vscode.window.showInformationMessage('Successfully created Localization Configuration! 🍻🍻🍻');

		var parentDirectory = args[0].path;

		const clickedOnDirectory = fs.lstatSync(parentDirectory).isDirectory();

		if(!clickedOnDirectory) {
			// Clicked on File so get the Parent Directory name
			parentDirectory = path.dirname(args[0].path);
		}

		const folderName = 'l10n';

		const directoryToCreate = path.join(parentDirectory, folderName);

		// Create Directory inside Parent Directory
		fs.mkdirSync(directoryToCreate, { recursive: true });

		const configFileName = 'localization_config.dart';

		const configFilePath = path.join(directoryToCreate, configFileName);

		var content = fs.createWriteStream(configFilePath)
		// Helper to write line by line 
		const  writeLine = (line) => content.write(`${line}\n`);  	
		writeLine('import \'package:localize_it_annotation/localize_it_annotation.dart\';');	
		writeLine('///');
		writeLine('@localize_it');
		writeLine('class LocaleConfiguration {');
		writeLine('  /// Expects a lanugage code in **lowercase**.');
		writeLine('  ///');
		writeLine('  /// Supports all the currently available `source_lang`');
		writeLine('  ///');
		writeLine('  /// on [DeepL](https://www.deepl.com/de/docs-api/translate-text/translate-text/).');
		writeLine('  /// ');
		writeLine('  /// Defaults to: \'de\' (German)');
 		writeLine('  static const String baseLanguageCode = \'de\';');
		content.write('\n');
		writeLine('  /// Expects language codes in **lowercase**.');
		writeLine('  ///');
		writeLine('  /// Supports all the currently available `target_lang`');
		writeLine('  ///');
		writeLine('  /// on [DeepL](https://www.deepl.com/de/docs-api/translate-text/translate-text/).');
		writeLine('  /// ');
		writeLine('  /// Defaults to: `[\'en\' (English), \'es\' (Spanish)]`');
		writeLine('  static const List<String> supportedLanguageCodes = [');
		writeLine('    \'en\',');
		writeLine('    \'es\',');
		writeLine('  ];');
		writeLine('  /// Providing a `deepLAuthKey` enables translation generation');
		writeLine('  ///  via the [DeepL API](https://www.deepl.com/de/pro-api?cta=header-pro-api/).');
		writeLine('  /// If no key is provided (empty String), all *marked Strings* (end with `.tr`) in your project');
		writeLine('  /// will get translated to `\'--missing translation--\'`');
		writeLine('  static const String deepLAuthKey = \'5bcb1202-12d5-2e63-f8ca-b087c47cad1b:fx\';');
		content.writeLine('\n');
		writeLine('  /// Enabling `useGetX` generates `Map<String, Map<String,String>> translationKeys` which can');
		writeLine('  /// simply be passed to `GetMaterialApp`.');
		writeLine('  static const bool useGetX = true;');

		writeLine('}');
		content.end()

		// Write content fo file
		fs.writeFileSync(configFilePath, content, 'utf8');

		const openPath = vscode.Uri.file(configFilePath);
		vscode.workspace.openTextDocument(openPath).then(doc => {
			vscode.window.showTextDocument(doc);

		});
	});

	context.subscriptions.push(disposable);
}

// This method is called when your extension is deactivated
function deactivate() {}

module.exports = {
	activate,
	deactivate
}
