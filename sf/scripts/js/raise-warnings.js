// `::warning file={name},line={line},endLine={endLine},title={title}::{message}`

const fs = require('fs');

const MAX_MESSAGES = 10;

const errors = [];
const warningFile = JSON.parse(fs.readFileSync('codescan.json', 'utf8'));

const errorMap = {};
for(let i = 1; i <= 5; i++) {
    errorMap[i] = [];
}

for(const warning of warningFile) {
    for(const violation of warning.violations) {
        let message = `::warning file=${warning.fileName},line=${violation.line},endLine=${violation.endLine},title=${violation.ruleName}::SEVERITY (${violation.severity}) ${violation.message}`
        message = message.replaceAll('\r','').replaceAll('\n','');
        // prioritize higher severity since GitHub actions max out at 10 warnings
        errorMap[violation.severity].push(message);
        errors.push(message);
    };
}

let currSeverity = 1;
let totalMessages = 0;

let hasMessage = (errorMap[currSeverity].length > 0);
let canPrintMoreMessages = (totalMessages <= MAX_MESSAGES);
while(hasMessage && canPrintMoreMessages) {
    console.log(errorMap[currSeverity].shift());

    totalMessages++;
    if(totalMessages === 10) {
        while(errorMap[currSeverity].length === 0) {
            currSeverity++;
        }
    }

    hasMessage = (errorMap[currSeverity].length > 0) && (currSeverity <= 5);
    canPrintMoreMessages = (totalMessages <= MAX_MESSAGES);
}