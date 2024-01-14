Tokenizer parser = new Tokenizer();
Map<String, String> queries = new Map<String, String> {
    'SELECT_ID_FROM_ACCOUNT' => 'SELECT Id FROM Account',
    'SELECT_ID_FROM_ACCOUNT_WHERE_NAME_EQUALS_JOHN' => 'SELECT Id FROM Account WHERE Name = \'John\'',
    'SELECT_ID_FROM_ACCOUNT_WHERE_NAME_EQUALS_JOHN_AND_ID_EQUALS_123' => 'SELECT Id FROM Account WHERE Name = \'John\' AND Id = \'123\'',
    'SELECT_ID_FROM_ACCOUNT_WITH_SUBQUERY_FIRST' => 'SELECT (SELECT Id FROM Contacts), Id FROM Account',
    'SELECT_ID_FROM_ACCOUNT_WITH_SUBQUERY_SECOND' => 'SELECT Id, (SELECT Id FROM Contacts) FROM Account',
    'SELECT_ID_FROM_ACCOUNT_WITH_SUBQUERY_IN_WHERE_CLAUSE' => 'SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact)',
    'SELECT_ID_FROM_ACCOUNT_WITH_SUBQUERY_IN_WHERE_CLAUSE_AND_NAME_EQUALS_JOHN' => 'SELECT Id FROM Account WHERE Id IN (SELECT AccountId FROM Contact) AND Name = \'John\'',
    'SELECT_ID_FROM_ACCOUNT_WITH_AND_OR' => 'SELECT Id FROM Account WHERE Name = \'John\' AND (Id = \'123\' OR Id = \'456\')',
    'SELECT_ID_FROM_ACCOUNT_WITH_THREE_ANDS' => 'SELECT Id FROM Contact WHERE FirstName = \'test\' AND LastName = \'test2\' AND Account.Name = \'testAcct\'',
    'SELECT_ID_FROM_ACCOUNT_WITH_BIND_VARIABLE' => 'SELECT Id, Name, BillingStreet FROM Account WHERE Id = :acctid2',
    'SELECT_COUNT_FROM_ACCOUNT' => 'SELECT COUNT() FROM Account'
};

System.debug(LoggingLevel.DEBUG, 'Tokenize: ' + parser.parse(queries.get('SELECT_COUNT_FROM_ACCOUNT')));