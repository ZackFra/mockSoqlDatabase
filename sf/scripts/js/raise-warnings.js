// `::warning file={name},line={line},endLine={endLine},title={title}::{message}`

const fs = require('fs');

const MAX_MESSAGES = 10;
const MAX_SEVERITY = 1;
const MIN_SEVERITY = 5;

const codeScanFile = JSON.parse(fs.readFileSync('codescan.json', 'utf8'));

const errorMap = {};
for(let i = 1; i <= 5; i++) {
    errorMap[i] = [];
}

for(const warning of codeScanFile) {
    for(const violation of warning.violations) {
        let message = `::warning file=${warning.fileName},line=${violation.line},endLine=${violation.endLine},title=${violation.ruleName}::SEVERITY (${violation.severity}) ${violation.message}`
        message = message.replaceAll('\r','').replaceAll('\n','');

        // group severity messages to prioritize higher severity messages
        errorMap[violation.severity].push(message);
    };
}

let currSeverity = MAX_SEVERITY;
let totalMessages = 0;


while(totalMessages++ < MAX_MESSAGES && currSeverity <= MIN_SEVERITY) {
    console.log(errorMap[currSeverity].shift());

    // find next severity level with messages
    while(currSeverity <= MIN_SEVERITY && errorMap[currSeverity].length === 0) {
        currSeverity++;
    }
}