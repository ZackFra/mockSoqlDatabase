// `::warning file={name},line={line},endLine={endLine},title={title}::{message}`

const fs = require('fs');

const codeScanFile = JSON.parse(fs.readFileSync('codescan.json', 'utf8'));

const errors = [];

for(const warning of codeScanFile) {
    for(const violation of warning.violations) {
        let message = `::warning file=${warning.fileName},line=${violation.line},endLine=${violation.endLine},title=${violation.ruleName}::SEVERITY (${violation.severity}) ${violation.message}`
        message = message.replaceAll('\r','').replaceAll('\n','');

        // group severity messages to prioritize higher severity messages
        errors.push(message);
    };
}

errors.sort((a, b) => a.severity - b.severity);

for(const error of errors) {
    console.log(error);
}