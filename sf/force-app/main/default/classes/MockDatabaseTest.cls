@IsTest
public with sharing class MockDatabaseTest {
    @IsTest
    public static void testInsert() {
        Account a = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);

        Account insertedAcct = (Account) mockDb.db.get('Account').get(a.Id);

        Assert.isNotNull(mockDb.db.get('Account').get(a.Id), 'Account was not inserted');
    }

    @IsTest
    public static void testQuerySingle() {
        Account a = new Account(Name = 'Test');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);

        Account queriedAcct = (Account) mockDb.query('SELECT Id, Name FROM Account');

        Assert.isNotNull(queriedAcct, 'Account was not queried');
    }

    @IsTest
    public static void testQueryMultiple() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(a);
        mockDb.doInsert(b);

        List<Account> queriedAccts = (List<Account>) mockDb.query('SELECT Id, Name FROM Account');

        Assert.isNotNull(queriedAccts, 'Accounts were not queried');
        Assert.areEqual(2, queriedAccts.size(), 'Incorrect number of accounts queried');
    }

    @IsTest
    public static void testInsertMultiple() {
        Account a = new Account(Name = 'Test');
        Account b = new Account(Name = 'Test2');
        MockDatabase mockDb = new MockDatabase();
        mockDb.doInsert(new List<SObject>{a, b});

        Account insertedAcctA = (Account) mockDb.db.get('Account').get(a.Id);
        Account insertedAcctB = (Account) mockDb.db.get('Account').get(b.Id);

        Assert.isNotNull(insertedAcctA, 'Account A was not inserted');
        Assert.isNotNull(insertedAcctB, 'Account B was not inserted');
    }
}