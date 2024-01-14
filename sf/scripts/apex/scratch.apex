MockDatabase mockDb = new MockDatabase();
for(Integer i = 0; i < 10; i++) {
    Account acct = new Account(
        Name = 'Test ' + i
    );
    mockDb.doInsert(acct);
}
Integer queriedAccts = (Integer) mockDb.query('SELECT COUNT() FROM Account WHERE Name IN (\'Test 1\', \'Test 2\')');
System.debug('Queried Accounts: ' + queriedAccts);