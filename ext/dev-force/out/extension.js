"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || function (mod) {
    if (mod && mod.__esModule) return mod;
    var result = {};
    if (mod != null) for (var k in mod) if (k !== "default" && Object.prototype.hasOwnProperty.call(mod, k)) __createBinding(result, mod, k);
    __setModuleDefault(result, mod);
    return result;
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.deactivate = exports.activate = void 0;
const vscode = __importStar(require("vscode"));
function executeAnon(debug, file) {
    if (!file) {
        vscode.window.showInformationMessage('No active file found.');
        return;
    }
    let dirPath = file.split('\\').slice(0, -1);
    dirPath.push('output.log');
    const outputDir = dirPath.join('\\');
    if (vscode.window.terminals.length > 0) {
        vscode.window.terminals[0].dispose();
    }
    const terminal = vscode.window.createTerminal('Dev-Force');
    if (debug) {
        terminal.sendText(`sf apex run --file ${file} | Select-String -Pattern USER_DEBUG > ${outputDir}`);
    }
    else {
        terminal.sendText(`sf apex run --file ${file} > ${outputDir}`);
    }
    terminal.show();
}
function activate(context) {
    let execAnonWithDebug = vscode.commands.registerCommand('dev-force.execAnonWithDebug', (document) => {
        if (!document?.fsPath) {
            vscode.window.showInformationMessage('No active file found.');
            return;
        }
        executeAnon(true, document.fsPath);
    });
    let execAnon = vscode.commands.registerCommand('dev-force.execAnon', (document) => {
        if (!document?.fsPath) {
            vscode.window.showInformationMessage('No active file found.');
            return;
        }
        executeAnon(false, document.fsPath);
    });
    console.log('Dev-Force extension activated.');
    context.subscriptions.push(execAnonWithDebug, execAnon);
}
exports.activate = activate;
// This method is called when your extension is deactivated
function deactivate() { }
exports.deactivate = deactivate;
//# sourceMappingURL=extension.js.map