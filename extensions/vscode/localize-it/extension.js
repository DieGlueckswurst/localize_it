
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
		writeLine('import \'package:annotations/annotations.dart\';');	
		content.write('\n');
		writeLine('@localized');
		writeLine('class LocaleConfiguration {');
		writeLine('  static const String baseLanguageCode = \'de\';');
		content.write('\n');
		writeLine('  static const List<String> supportedLanguageCodes = [');
		writeLine('    \'de\',');
		writeLine('    \'en\',');
		writeLine('  ];');
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
