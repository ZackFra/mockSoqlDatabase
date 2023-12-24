Tokenizer parser = new Tokenizer();
Map<String, String> queries = new Map<String, String> {
    'SELECT_ID_FROM_ACCOUNT' => 'SELECT Id FROM Account',
    'SELECT_ID_FROM_ACCOUNT_WHERE_NAME_EQUALS_JOHN' => 'SELECT Id FROM Account WHERE Name = \'John\'',
    'SELECT_ID_FROM_ACCOUNT_WHERE_NAME_EQUALS_JOHN_AND_ID_EQUALS_123' => 'SELECT Id FROM Account WHERE Name = \'John\' AND Id = \'123\'',
    'SELECT_ID_FROM_ACCOUNT_WITH_SUBQUERY' => 'SELECT (SELECT Id FROM Contacts), Id FROM Account'
};

System.debug(LoggingLevel.DEBUG, 'Tokenize: ' + parser.parse(queries.get('SELECT_ID_FROM_ACCOUNT_WITH_SUBQUERY')));