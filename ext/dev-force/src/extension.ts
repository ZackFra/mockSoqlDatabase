import * as vscode from 'vscode';

function executeAnon(debug: Boolean, file?: string) {

	if(!file) {
		vscode.window.showInformationMessage('No active file found.');
		return;
	}

	let dirPath = file.split('\\').slice(0, -1);
	dirPath.push('output.log');
	const outputDir = dirPath.join('\\');
	if(vscode.window.terminals.length > 0) {
		vscode.window.terminals[0].dispose();
	}
	const terminal = vscode.window.createTerminal('Dev-Force');
	if(debug) {
		terminal.sendText(`sf apex run --file ${file} | Select-String -Pattern USER_DEBUG > ${outputDir}`);
	} else {
		terminal.sendText(`sf apex run --file ${file} > ${outputDir}`);
	}
	terminal.show();
}

export function activate(context: vscode.ExtensionContext) {
	let execAnonWithDebug = vscode.commands.registerCommand('dev-force.execAnonWithDebug', (document: vscode.Uri) => {
		if(!document?.fsPath) {
			vscode.window.showInformationMessage('No active file found.');
			return;
		}
		executeAnon(true, document.fsPath);
	});

	let execAnon = vscode.commands.registerCommand('dev-force.execAnon', (document: vscode.Uri) => {
		if(!document?.fsPath) {
			vscode.window.showInformationMessage('No active file found.');
			return;
		}
		executeAnon(false, document.fsPath);	
	});

	console.log('Dev-Force extension activated.');

	context.subscriptions.push(execAnonWithDebug, execAnon);
}

// This method is called when your extension is deactivated
export function deactivate() {}
