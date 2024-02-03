`::warning file={name},line={line},endLine={endLine},title={title}::{message}`

const fs = require('fs');
const errors = [];
JSON.parse(fs.readFileSync('codescan.json', 'utf8'))
.forEach((warning) => {
    warning.violations.forEach((violation) => {
        let message = `::warning file=${warning.fileName},line=${violation.line},endLine=${violation.endLine},title=${violation.ruleName}::SEVERITY (${violation.severity}) ${violation.message}`
        message = message.replaceAll('\r','').replaceAll('\n','');
        errors.push(message);
    });
});
errors.forEach((error) => {
    console.log(error);
});

